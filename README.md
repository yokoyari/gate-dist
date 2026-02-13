<img width="640" height="480" alt="gate_vs_nginx_rps" src="https://github.com/user-attachments/assets/8d0094d8-b019-42c4-8526-7559bf119c73" />
<img width="640" height="480" alt="gate_vs_nginx_p99" src="https://github.com/user-attachments/assets/b2e30010-c3ad-4ae9-b7ee-944f6d44e0a0" />
# Gate v0.92 极致性能版 Linux ARM64 性能测试报告

**测试日期**: 2026-02-13  
**版本**: v0.92 (极致性能优化版 - Linux ARM64)  
**测试环境**: Docker (ARM64 Ubuntu 22.04) vs Nginx (Ubuntu)  
**状态**: 测试完成 ✅

---

## 准备工作

运行测试前需要准备以下工具：

### 1. wrk (系统工具)

压测工具，需要安装在宿主机或容器内：

```bash
# Ubuntu/Debian
sudo apt install wrk

# CentOS/RHEL
sudo yum install wrk

# macOS
brew install wrk
```

### 2. nginx (容器内安装)

对比基准服务器，需要在测试容器内安装：

```bash
# 在容器内执行
apt-get update && apt-get install -y nginx

# 或使用 Docker
docker run -d --name nginx -p 8081:80 nginx:latest
```

---

## 运行测试

```bash
cd test
chmod +x run_stress_test.sh
./run_stress_test.sh
```

测试脚本会自动：
1. 检查工具是否安装
2. 启动 Gate 服务 (端口 8090)
3. 运行压力测试 (低/中/高并发)
4. 启动 Nginx 服务 (端口 8081)
5. 运行对比测试
6. 生成对比报告 (含详细 Markdown 格式)

---

## 测试结果汇总

| 并发数 | Gate RPS | Nginx RPS | 领先 |
|--------|----------|-----------|------|
| 100    | 560,958  | 199,732   | **+180.9%** |
| 1000   | 666,898  | 197,452   | **+237.8%** |
| 5000   | 531,306  | 181,913   | **+192.1%** |

---

## 技术特性

- **事件循环**: epoll (Linux)
- **批量accept**: BatchHandler 64连接
- **连接管理**: ConnRingBuffer O(1)
- **内存池**: WorkerArena 64MB预分配
- **Worker数**: 8

---

## 结论

- Gate 在所有并发级别均大幅优于 Nginx
- 中并发(1000)时领先 **+237.8%**，性能是 Nginx 的 **3.4倍**
- 高并发(5000)时依然保持 **+192.1%** 领先
- Linux ARM64 环境下表现优异

---

详细测试报告请查看: `test/PERFORMANCE_REPORT.md`

---

**报告生成时间**: 2026-02-13  
**版本**: Gate v0.92 极致性能版  
**状态**: 测试完成 ✅

## Gate v0.92 (Technology Preview)

This repository provides binary releases for performance testing only.

- Source code is not open-sourced at this stage
- Redistribution or commercial use is not permitted
- Feedback and benchmarks are welcome
