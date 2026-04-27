#!/bin/bash
shape_prep_env() {
  export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/sbin:/usr/bin:/bin:${PATH:-}"
}

shape_prep_load_modules() {
  shape_prep_env
  command -v modprobe >/dev/null 2>&1 || return 0
  # wondershaper (HTB+SFQ+u32) 与入向 IFB+mired
  modprobe sch_htb 2>/dev/null || true
  modprobe sch_sfq 2>/dev/null || true
  modprobe cls_u32 2>/dev/null || true
  modprobe sch_ingress 2>/dev/null || true
  modprobe ifb 2>/dev/null || true
  modprobe act_mirred 2>/dev/null || true
  modprobe act_skbedit 2>/dev/null || true
}

# resolve tc path; return 1 if failed (caller should exit)
shape_prep_tc_resolve() {
  shape_prep_env
  TC_BIN="$(command -v tc || true)"
  if [ -z "$TC_BIN" ]; then
    for p in /usr/sbin/tc /sbin/tc; do
      if [ -x "$p" ]; then TC_BIN="$p"; break; fi
    done
  fi
  [ -n "$TC_BIN" ]
}

# multi-queue card root queue is usually mq; need to delete multiple times to clear htb/mq/ingress, avoid wondershaper reporting Exclusivity / File exists
shape_prep_clear_iface_qdisc() {
  local dev="$1"
  local i
  ip link show "$dev" &>/dev/null || return 0
  for i in 1 2 3 4 5; do
    "$TC_BIN" qdisc del dev "$dev" ingress >/dev/null 2>&1 || true
    "$TC_BIN" qdisc del dev "$dev" root >/dev/null 2>&1 || true
  done
}
