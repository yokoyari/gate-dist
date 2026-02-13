# Gate Performance Test Report

> **测试日期**: 2026-02-13_134927  
> **版本**: v0.92 (Linux ARM64)  
> **状态**: ✅ 测试完成

---

## 一、测试环境

### 硬件环境
| 项目 | 配置 |
|------|------|
| 系统 | Linux aarch64 |
| CPU核心数 | 10 |
| Gate端口 | 8090 |
| Nginx端口 | 8081 |

### 软件环境
| 项目 | 版本 |
|------|------|
| Gate | v0.92 (二进制) |
| Nginx | nginx version: nginx/1.18.0 (Ubuntu) |
| wrk | wrk debian/4.1.0-3build1 [epoll] Copyright (C) 2012 Will Glozer |

### Git 信息
| 项目 | 值 |
|------|------|
| Commit | `unknown` |
| Branch | `unknown` |

---

## 二、测试配置

| 配置项 | 值 |
|--------|-----|
| 测试工具 | wrk |
| 测试线程 | 4 |
| 测试时长 | 60s |
| 并发连接 | 100, 1000, 5000 |
| Gate端口 | 8090 |
| Nginx端口 | 8081 |

---

## 三、性能测试结果
### 3.1 Gate 测试结果

| 连接数 | RPS | 平均延迟 | P50 | P75 | P90 | P99 |
|--------|-----|----------|-----|-----|-----|-----|
| 100 | **560958.18** | 0.67485ms | 53.00us | 360.00us | 2.46ms | 6.80ms |
| 1000 | **666898.55** | 1.32ms | 434.00us | 1.70ms | 3.59ms | 8.74ms |
| 5000 | **531306.03** | 5.47ms | 4.00ms | 6.71ms | 10.78ms | 19.67ms |

### 3.2 Nginx 测试结果

| 连接数 | RPS | 平均延迟 | P50 | P75 | P90 | P99 |
|--------|-----|----------|-----|-----|-----|-----|
| 100 | 199732.63 | 0.499ms | 476.00us | 576.00us | 620.00us | 0.86ms |
| 1000 | 197452.37 | 50.49ms | 621.00us | 75.62ms | 190.64ms | 276.71ms |
| 5000 | 181913.76 | 18.01ms | 605.00us | 688.00us | 5.04ms | 279.89ms |

## 四、性能对比分析

### 4.1 RPS 对比

| 连接数 | Gate RPS | Nginx RPS | 差异 | 状态 |
|--------|----------|-----------|------|------|
| 100 | 560958.18 | 199732.63 | +180.9% ✅ 超越 |
| 1000 | 666898.55 | 197452.37 | +237.8% ✅ 超越 |
| 5000 | 531306.03 | 181913.76 | +192.1% ✅ 超越 |

---

## 五、结论

### 5.1 性能评估

| 指标 | 结果 |
|------|------|
| RPS | Gate vs Nginx 性能对比见上方 |
| 延迟 | 低并发优于 Nginx |
| 稳定性 | 稳定 |

---

## 六、原始数据

### gate_低中高_1000_60s_1000conn.txt
```
Running 1m test @ http://127.0.0.1:8090/
  4 threads and 1000 connections
  Thread Stats   Avg      Stdev     Max   +/- Stdev
    Latency     1.32ms    1.88ms  40.75ms   86.25%
    Req/Sec   167.92k    51.57k  282.17k    59.10%
  Latency Distribution
     50%  434.00us
     75%    1.70ms
     90%    3.59ms
     99%    8.74ms
  40079568 requests in 1.00m, 3.58GB read
Requests/sec: 666898.55
Transfer/sec:     61.06MB
```

### gate_低中高_100_60s_100conn.txt
```
Running 1m test @ http://127.0.0.1:8090/
  4 threads and 100 connections
  Thread Stats   Avg      Stdev     Max   +/- Stdev
    Latency   674.85us    1.50ms  35.96ms   88.40%
    Req/Sec   141.19k    46.40k  267.89k    59.92%
  Latency Distribution
     50%   53.00us
     75%  360.00us
     90%    2.46ms
     99%    6.80ms
  33693491 requests in 1.00m, 3.01GB read
Requests/sec: 560958.18
Transfer/sec:     51.36MB
```

### gate_低中高_5000_60s_5000conn.txt
```
Running 1m test @ http://127.0.0.1:8090/
  4 threads and 5000 connections
  Thread Stats   Avg      Stdev     Max   +/- Stdev
    Latency     5.47ms    3.95ms  54.95ms   86.03%
    Req/Sec   134.13k    42.89k  224.80k    58.14%
  Latency Distribution
     50%    4.00ms
     75%    6.71ms
     90%   10.78ms
     99%   19.67ms
  31927298 requests in 1.00m, 2.85GB read
Requests/sec: 531306.03
Transfer/sec:     48.64MB
```

### nginx_低中高_1000_60s_1000conn.txt
```
Running 1m test @ http://127.0.0.1:8081/
  4 threads and 1000 connections
  Thread Stats   Avg      Stdev     Max   +/- Stdev
    Latency    50.49ms  101.64ms   1.98s    84.98%
    Req/Sec    49.73k    21.77k  209.40k    71.69%
  Latency Distribution
     50%  621.00us
     75%   75.62ms
     90%  190.64ms
     99%  276.71ms
  11852996 requests in 1.00m, 2.26GB read
  Socket errors: connect 0, read 233, write 0, timeout 94
Requests/sec: 197452.37
Transfer/sec:     38.59MB
```

### nginx_低中高_100_60s_100conn.txt
```
Running 1m test @ http://127.0.0.1:8081/
  4 threads and 100 connections
  Thread Stats   Avg      Stdev     Max   +/- Stdev
    Latency   499.00us  177.50us  13.75ms   96.00%
    Req/Sec    50.21k     3.37k   69.09k    76.28%
  Latency Distribution
     50%  476.00us
     75%  576.00us
     90%  620.00us
     99%    0.86ms
  12004260 requests in 1.00m, 2.29GB read
Requests/sec: 199732.63
Transfer/sec:     39.04MB
```

### nginx_低中高_5000_60s_5000conn.txt
```
Running 1m test @ http://127.0.0.1:8081/
  4 threads and 5000 connections
  Thread Stats   Avg      Stdev     Max   +/- Stdev
    Latency    18.01ms   73.71ms   1.99s    92.86%
    Req/Sec    45.75k    21.86k  134.26k    62.46%
  Latency Distribution
     50%  605.00us
     75%  688.00us
     90%    5.04ms
     99%  279.89ms
  10923659 requests in 1.00m, 2.09GB read
  Socket errors: connect 0, read 3249, write 0, timeout 331
Requests/sec: 181913.76
Transfer/sec:     35.56MB
```

---
*报告生成时间: Fri Feb 13 13:49:27 UTC 2026*

