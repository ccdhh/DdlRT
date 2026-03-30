#!/bin/bash
# 供 limit_*.sh source：为 tc/wondershaper 预加载队列规则所需内核模块。
# 若仍报 "qdisc kind is unknown"，在节点上安装额外模块包，例如:
#   apt-get install -y iproute2 linux-modules-extra-$(uname -r)
# 然后 modprobe 或重启。

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

# 解析 tc 路径；失败返回 1（调用方应退出）
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

# 多队列网卡根队列常为 mq；不先删掉 root，wondershaper 的 htb 加不上（脚本仍可能 exit 0）
shape_prep_clear_iface_qdisc() {
  local dev="$1"
  ip link show "$dev" &>/dev/null || return 0
  "$TC_BIN" qdisc del dev "$dev" ingress >/dev/null 2>&1 || true
  "$TC_BIN" qdisc del dev "$dev" root >/dev/null 2>&1 || true
}
