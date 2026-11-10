#!/usr/bin/env python3
"""Collect per-process CPU, GPU (DRM fdinfo / NVIDIA), and Memory telemetry for TopLeftBar."""

from __future__ import annotations

import os
import pwd
import shutil
import subprocess
import time


def _get_mem_total_kb() -> int:
    try:
        with open("/proc/meminfo", encoding="utf-8") as f:
            for line in f:
                if line.startswith("MemTotal:"):
                    return max(1, int(line.split()[1]))
    except OSError:
        pass
    return 1


def _get_total_cpu_jiffies() -> tuple[int, int]:
    total_jiffies = 0
    num_cores = 0
    try:
        with open("/proc/stat", encoding="utf-8") as f:
            for line in f:
                if line.startswith("cpu "):
                    parts = line.split()[1:]
                    total_jiffies = sum(int(x) for x in parts[:8])
                elif line.startswith("cpu") and line[3:4].isdigit():
                    num_cores += 1
    except OSError:
        pass
    return max(1, total_jiffies), max(1, num_cores)


def _get_uptime_sec() -> float:
    try:
        with open("/proc/uptime", encoding="utf-8") as f:
            return float(f.read().split()[0])
    except (OSError, ValueError, IndexError):
        return 1.0


def _get_nvidia_gpu_procs() -> dict[int, tuple[float, int]]:
    """Return {pid: (sm_util_pct, fb_mem_kb)} when NVIDIA kernel module is active."""
    result: dict[int, tuple[float, int]] = {}
    if not os.path.isdir("/sys/module/nvidia"):
        return result
    smi = shutil.which("nvidia-smi")
    if not smi:
        return result
    try:
        proc = subprocess.run(
            [smi, "pmon", "-c", "1", "-s", "um"],
            capture_output=True,
            text=True,
            timeout=0.8,
            check=False,
        )
        for line in proc.stdout.splitlines():
            line = line.strip()
            if not line or line.startswith("#"):
                continue
            parts = line.split()
            if len(parts) >= 6 and parts[1].isdigit():
                pid = int(parts[1])
                sm_pct = float(parts[3]) if parts[3].isdigit() else 0.0
                fb_mb = int(parts[5]) if parts[5].isdigit() else 0
                prev_sm, prev_kb = result.get(pid, (0.0, 0))
                result[pid] = (max(prev_sm, sm_pct), max(prev_kb, fb_mb * 1024))
    except (OSError, subprocess.SubprocessError, ValueError):
        pass
    return result


def _scan_drm_fdinfo(pdir: str) -> tuple[int, int]:
    """Sum DRM GPU engine time (ns) and resident memory (KiB) across unique DRM clients."""
    gpu_ns = 0
    gpu_mem_kb = 0
    fd_dir = f"{pdir}/fd"
    if not os.access(fd_dir, os.R_OK):
        return 0, 0

    seen_clients: set[str] = set()
    try:
        with os.scandir(fd_dir) as it:
            for fd_entry in it:
                try:
                    target = os.readlink(fd_entry.path)
                except OSError:
                    continue
                if not target.startswith("/dev/dri/"):
                    continue
                fdi_path = f"{pdir}/fdinfo/{fd_entry.name}"
                try:
                    with open(fdi_path, encoding="utf-8", errors="replace") as fdi:
                        cid = ""
                        eng_ns = 0
                        mem_k = 0
                        for line in fdi:
                            if line.startswith("drm-client-id:"):
                                cid = line.split(":", 1)[1].strip()
                            elif line.startswith("drm-engine-"):
                                parts = line.split(":", 1)[1].split()
                                if len(parts) >= 2 and parts[-1] == "ns" and parts[0].isdigit():
                                    eng_ns += int(parts[0])
                            elif line.startswith(("drm-resident-", "drm-total-")):
                                parts = line.split(":", 1)[1].split()
                                if parts and parts[0].isdigit():
                                    val = int(parts[0])
                                    if len(parts) > 1 and parts[1] == "MiB":
                                        val *= 1024
                                    mem_k = max(mem_k, val)
                        if cid and cid not in seen_clients:
                            seen_clients.add(cid)
                            gpu_ns += eng_ns
                            gpu_mem_kb += mem_k
                except OSError:
                    continue
    except OSError:
        pass
    return gpu_ns, gpu_mem_kb


def main() -> None:
    ts_ns = time.monotonic_ns()
    clk_tck = os.sysconf(os.sysconf_names.get("SC_CLK_TCK", "SC_CLK_TCK"))
    page_size_kb = max(1, os.sysconf("SC_PAGE_SIZE") // 1024)
    mem_total_kb = _get_mem_total_kb()
    total_jiffies, num_cores = _get_total_cpu_jiffies()
    uptime_sec = _get_uptime_sec()
    nv_procs = _get_nvidia_gpu_procs()

    uid_cache: dict[int, str] = {}

    def get_user(uid: int) -> str:
        if uid not in uid_cache:
            try:
                uid_cache[uid] = pwd.getpwuid(uid).pw_name
            except KeyError:
                uid_cache[uid] = str(uid)
        return uid_cache[uid]

    print(f"META|{ts_ns}|{total_jiffies}|{mem_total_kb}|{clk_tck}|{uptime_sec:.2f}|{num_cores}")

    try:
        proc_entries = list(os.scandir("/proc"))
    except OSError:
        return

    for entry in proc_entries:
        if not entry.name.isdigit():
            continue
        pid = int(entry.name)
        pdir = entry.path
        try:
            with open(f"{pdir}/stat", "rb") as f:
                stat_bytes = f.read()
            lparen = stat_bytes.find(b"(")
            rparen = stat_bytes.rfind(b")")
            if lparen < 0 or rparen < 0:
                continue
            comm = (
                stat_bytes[lparen + 1 : rparen].decode("utf-8", "replace").replace("|", " ").replace("\n", " ").strip()
            )
            rest = stat_bytes[rparen + 2 :].split()
            if len(rest) < 22:
                continue

            utime = int(rest[11])
            stime = int(rest[12])
            threads = int(rest[17])
            starttime = int(rest[19])
            rss_pages = int(rest[21])
            if rss_pages <= 0:
                # Skip kernel worker threads with 0 user space RSS so the table stays clean like btop
                continue
            rss_kb = rss_pages * page_size_kb

            uid = os.stat(pdir).st_uid
            user = get_user(uid).replace("|", " ")

            cmd = comm
            try:
                with open(f"{pdir}/cmdline", "rb") as cf:
                    raw_cmd = cf.read(256)
                if raw_cmd:
                    parts = [p.decode("utf-8", "replace") for p in raw_cmd.split(b"\x00") if p]
                    if parts:
                        exe = os.path.basename(parts[0]) or comm
                        args = " ".join(parts[1:])
                        cmd = f"{exe} {args}".strip() if args else exe
                        cmd = cmd.replace("|", " ").replace("\n", " ")[:120]
            except OSError:
                pass

            gpu_ns, gpu_mem_kb = _scan_drm_fdinfo(pdir)
            if pid in nv_procs:
                nv_pct, nv_mem = nv_procs[pid]
                gpu_mem_kb = max(gpu_mem_kb, nv_mem)
                if gpu_ns == 0 and nv_pct > 0:
                    gpu_ns = int(nv_pct * 1e7)

            print(
                f"PROC|{pid}|{comm}|{user}|{threads}|{utime + stime}|{rss_kb}|{gpu_ns}|{gpu_mem_kb}|{starttime}|{cmd}"
            )
        except (OSError, ValueError, IndexError):
            continue


if __name__ == "__main__":
    main()
