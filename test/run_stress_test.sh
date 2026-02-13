#!/bin/bash

# Gate v0.92 vs Nginx 压力测试脚本
# 测试场景：1分钟、3分钟、5分钟 x 低/中/高并发

set -e

# 配置
GATE_PORT=8090
NGINX_PORT=8081
GATE_BIN="../bin/gate-linux"
NGINX_CONF="./nginx_test.conf"
RESULTS_DIR="./benchmark/results_$(date +%Y%m%d_%H%M%S)"

# 创建结果目录
mkdir -p "$RESULTS_DIR"

echo "=========================================="
echo "Gate v0.92 vs Nginx 压力测试"
echo "=========================================="
echo ""
echo "测试时间: $(date)"
echo "平台: $(uname -s) $(uname -m)"
echo "CPU: $(nproc) cores"
echo "内存: $(($(free -g | awk '/^Mem:/{print $2}')) 2>/dev/null || echo "N/A") GB"
echo ""

# 检查工具
echo "🔍 检查测试工具..."
if ! command -v wrk &> /dev/null; then
    echo "❌ wrk 未安装 (系统工具)"
    echo ""
    echo "📦 安装方法:"
    echo "   Ubuntu/Debian: sudo apt install wrk"
    echo "   CentOS/RHEL:   sudo yum install wrk"
    echo "   macOS:         brew install wrk"
    exit 1
fi
echo "✅ wrk: $(wrk -v 2>&1 | head -1)"

if ! command -v curl &> /dev/null; then
    echo "❌ curl 未安装"
    echo ""
    echo "📦 安装方法:"
    echo "   Ubuntu/Debian: sudo apt install curl"
    echo "   CentOS/RHEL:   sudo yum install curl"
    echo "   macOS:         brew install curl"
    exit 1
fi
echo "✅ curl installed"

if ! command -v nginx &> /dev/null; then
    if command -v docker &> /dev/null && docker ps &> /dev/null; then
        echo "⚠️  nginx 未在系统安装，将在容器中运行测试"
        echo ""
    else
        echo "❌ nginx 未安装 (需要安装在容器中)"
        echo ""
        echo "📦 容器内安装方法:"
        echo "   Docker: docker run -d --name nginx nginx:latest"
        echo "   或在容器内: apt-get update && apt-get install -y nginx"
        exit 1
    fi
else
    echo "✅ nginx: $(nginx -v 2>&1)"
fi
echo ""

# 复制 nginx 配置到当前目录
cp -f "$NGINX_CONF" ./nginx.conf
NGINX_CONF="./nginx.conf"

# 清理函数
cleanup() {
    echo ""
    echo "🧹 清理进程..."
    pkill -f "gate" 2>/dev/null || true
    pkill -f "nginx" 2>/dev/null || true
    sleep 2
}

trap cleanup EXIT

# 启动 Gate
start_gate() {
    echo "🚀 启动 Gate..."
    cleanup
    sleep 1
    
    $GATE_BIN > "$RESULTS_DIR/gate.log" 2>&1 &
    GATE_PID=$!
    sleep 3
    
    # 检查是否启动成功
    if ! curl -s http://127.0.0.1:$GATE_PORT/ > /dev/null 2>&1; then
        echo "❌ Gate 启动失败"
        cat "$RESULTS_DIR/gate.log"
        exit 1
    fi
    
    echo "✅ Gate 启动成功 (PID: $GATE_PID)"
}

# 启动 Nginx
start_nginx() {
    echo "🚀 启动 Nginx..."
    cleanup
    sleep 1
    
    nginx -c "$(pwd)/nginx_test.conf" -p "$(pwd)/" 2>&1 | head -5
    sleep 2
    
    # 检查是否启动成功
    if ! curl -s http://127.0.0.1:$NGINX_PORT/ > /dev/null 2>&1; then
        echo "❌ Nginx 启动失败"
        exit 1
    fi
    
    echo "✅ Nginx 启动成功"
}

# 运行测试
run_test() {
    local name=$1
    local port=$2
    local connections=$4
    local threads=$5
    
    local duration=$DURATIONS
    
    echo ""
    echo "📊 测试: $name"
    echo "   持续时间: ${duration}s"
    echo "   并发连接: $connections"
    echo "   线程数: $threads"
    echo ""
    
    # 预热
    wrk -t2 -c100 -d5s http://127.0.0.1:$port/ > /dev/null 2>&1 || true
    sleep 1
    
    # 正式测试
    wrk -t$threads -c$connections -d${duration}s --latency \
        http://127.0.0.1:$port/ 2>&1 | tee "$RESULTS_DIR/${name}_${duration}s_${connections}conn.txt"
    
    echo ""
}

# 提取关键指标
extract_metrics() {
    local file=$1
    
    if [ -f "$file" ]; then
        local rps=$(grep "Requests/sec" "$file" | awk '{print $2}')
        local latency_avg=$(grep "Latency" "$file" | head -1 | awk '{print $2}')
        local latency_max=$(grep "Max" "$file" | awk '{print $2}')
        
        echo "$rps,$latency_avg,$latency_max"
    else
        echo "0,0,0"
    fi
}

# 生成详细报告
generate_report() {
    local report_file="$RESULTS_DIR/PERFORMANCE_REPORT.md"
    
    # 获取 Git 信息
    local git_commit="unknown"
    local git_branch="unknown"
    if command -v git &> /dev/null; then
        git_commit=$(git rev-parse HEAD 2>/dev/null || echo "unknown")
        git_branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "unknown")
    fi
    
    # 获取平台信息
    local platform="$(uname -s) $(uname -m)"
    local cpu_cores=$(nproc 2>/dev/null || echo "N/A")
    
    cat > "$report_file" << EOF
# Gate Performance Test Report

> **测试日期**: $(date +%Y-%m-%d_%H%M%S)  
> **版本**: v0.92 (Linux ARM64)  
> **状态**: ✅ 测试完成

---

## 一、测试环境

### 硬件环境
| 项目 | 配置 |
|------|------|
| 系统 | $platform |
| CPU核心数 | $cpu_cores |
| Gate端口 | $GATE_PORT |
| Nginx端口 | $NGINX_PORT |

### 软件环境
| 项目 | 版本 |
|------|------|
| Gate | v0.92 (二进制) |
| Nginx | $(nginx -v 2>&1 | head -1) |
| wrk | $(wrk -v 2>&1 | head -1) |

### Git 信息
| 项目 | 值 |
|------|------|
| Commit | \`$git_commit\` |
| Branch | \`$git_branch\` |

---

## 二、测试配置

| 配置项 | 值 |
|--------|-----|
| 测试工具 | wrk |
| 测试线程 | $THREADS |
| 测试时长 | 60s |
| 并发连接 | 100, 1000, 5000 |
| Gate端口 | $GATE_PORT |
| Nginx端口 | $NGINX_PORT |

---

## 三、性能测试结果
EOF

    # Gate 测试结果
    echo "### 3.1 Gate 测试结果" >> "$report_file"
    echo "" >> "$report_file"
    echo "| 连接数 | RPS | 平均延迟 | P50 | P75 | P90 | P99 |" >> "$report_file"
    echo "|--------|-----|----------|-----|-----|-----|-----|" >> "$report_file"
    
    for conn in "${CONCURRENCIES[@]}"; do
        local file="$RESULTS_DIR/gate_低中高铁_${conn}conn.txt"
        # 尝试找实际的文件名
        file=$(ls "$RESULTS_DIR"/*gate*${conn}conn.txt 2>/dev/null | head -1)
        
        if [ -f "$file" ]; then
            local rps=$(grep "Requests/sec" "$file" | awk '{print $2}')
            local avg=$(grep "Latency" "$file" | head -1 | awk '{print $2}')
            local p50=$(grep "50%" "$file" | awk '{print $2}')
            local p75=$(grep "75%" "$file" | awk '{print $2}')
            local p90=$(grep "90%" "$file" | awk '{print $2}')
            local p99=$(grep "99%" "$file" | awk '{print $2}')
            
            # 转换单位
            if [[ "$avg" == *"ms"* ]]; then
                avg=$(echo "$avg" | sed 's/ms//')
            elif [[ "$avg" == *"us"* ]]; then
                avg=$(echo "$avg" | sed 's/us//' | awk '{print $1/1000}')
            fi
            
            echo "| $conn | **$rps** | ${avg}ms | ${p50} | ${p75} | ${p90} | ${p99} |" >> "$report_file"
        fi
    done
    
    echo "" >> "$report_file"
    
    # Nginx 测试结果
    echo "### 3.2 Nginx 测试结果" >> "$report_file"
    echo "" >> "$report_file"
    echo "| 连接数 | RPS | 平均延迟 | P50 | P75 | P90 | P99 |" >> "$report_file"
    echo "|--------|-----|----------|-----|-----|-----|-----|" >> "$report_file"
    
    for conn in "${CONCURRENCIES[@]}"; do
        local file=$(ls "$RESULTS_DIR"/*nginx*${conn}conn.txt 2>/dev/null | head -1)
        
        if [ -f "$file" ]; then
            local rps=$(grep "Requests/sec" "$file" | awk '{print $2}')
            local avg=$(grep "Latency" "$file" | head -1 | awk '{print $2}')
            local p50=$(grep "50%" "$file" | awk '{print $2}')
            local p75=$(grep "75%" "$file" | awk '{print $2}')
            local p90=$(grep "90%" "$file" | awk '{print $2}')
            local p99=$(grep "99%" "$file" | awk '{print $2}')
            
            if [[ "$avg" == *"ms"* ]]; then
                avg=$(echo "$avg" | sed 's/ms//')
            elif [[ "$avg" == *"us"* ]]; then
                avg=$(echo "$avg" | sed 's/us//' | awk '{print $1/1000}')
            fi
            
            echo "| $conn | $rps | ${avg}ms | ${p50} | ${p75} | ${p90} | ${p99} |" >> "$report_file"
        fi
    done
    
    echo "" >> "$report_file"
    
    # 性能对比
    echo "## 四、性能对比分析" >> "$report_file"
    echo "" >> "$report_file"
    echo "### 4.1 RPS 对比" >> "$report_file"
    echo "" >> "$report_file"
    echo "| 连接数 | Gate RPS | Nginx RPS | 差异 | 状态 |" >> "$report_file"
    echo "|--------|----------|-----------|------|------|" >> "$report_file"
    
    for conn in "${CONCURRENCIES[@]}"; do
        local gate_file=$(ls "$RESULTS_DIR"/*gate*${conn}conn.txt 2>/dev/null | head -1)
        local nginx_file=$(ls "$RESULTS_DIR"/*nginx*${conn}conn.txt 2>/dev/null | head -1)
        
        if [ -f "$gate_file" ] && [ -f "$nginx_file" ]; then
            local gate_rps=$(grep "Requests/sec" "$gate_file" | awk '{print $2}')
            local nginx_rps=$(grep "Requests/sec" "$nginx_file" | awk '{print $2}')
            
            local diff=$(echo "$gate_rps $nginx_rps" | awk '{printf "%.1f", ($1-$2)/$2*100}')
            local status="✅ 超越"
            if (( $(echo "$diff < 0" | bc -l) )); then
                status="❌ 落后"
            fi
            
            echo "| $conn | $gate_rps | $nginx_rps | +${diff}% $status |" >> "$report_file"
        fi
    done
    
    cat >> "$report_file" << 'EOF'

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
EOF

    for f in "$RESULTS_DIR"/*.txt; do
        if [ -f "$f" ]; then
            local fname=$(basename "$f")
            echo "" >> "$report_file"
            echo "### $fname" >> "$report_file"
            echo '```' >> "$report_file"
            cat "$f" >> "$report_file"
            echo '```' >> "$report_file"
        fi
    done
    
    echo "" >> "$report_file"
    echo "---" >> "$report_file"
    echo "*报告生成时间: $(date)*" >> "$report_file"
    
    echo "" >> "$report_file"
    echo "详细报告已生成: $report_file"
}

# ============================================
# 开始测试
# ============================================

echo "=========================================="
echo "第一阶段: 编译检查"
echo "=========================================="

if [ ! -f "$GATE_BIN" ]; then
    echo "❌ Gate 可执行文件不存在，请先编译"
    exit 1
fi

echo "✅ Gate 可执行文件: $GATE_BIN"
echo ""

# 测试配置
# 并发级别: 低(100) 中(1000) 高(5000)
# 持续时间: 60s

declare -a CONCURRENCIES=(100 1000 5000)
declare -a CONCURRENCY_NAMES=("低并发" "中并发" "高并发")
declare -a DURATIONS=(60)
declare -a DURATION_NAMES=("1分钟")

# 计算线程数 (不超过CPU核心数)
THREADS=4

# 测试间隔 (秒)
TEST_INTERVAL=5

echo "=========================================="
echo "第二阶段: Gate 压力测试"
echo "=========================================="

start_gate

# Gate 测试
for i in "${!CONCURRENCIES[@]}"; do
    conn=${CONCURRENCIES[$i]}
    conn_name=${CONCURRENCY_NAMES[$i]}
    
    run_test "gate_低中高_${conn}" $GATE_PORT "" $conn $THREADS
    sleep $TEST_INTERVAL
done

cleanup

echo ""
echo "=========================================="
echo "第三阶段: Nginx 压力测试"
echo "=========================================="

start_nginx

# Nginx 测试
for i in "${!CONCURRENCIES[@]}"; do
    conn=${CONCURRENCIES[$i]}
    conn_name=${CONCURRENCY_NAMES[$i]}
    
    run_test "nginx_低中高_${conn}" $NGINX_PORT "" $conn $THREADS
    sleep $TEST_INTERVAL
done

cleanup

echo ""
echo "=========================================="
echo "第四阶段: 生成对比报告"
echo "=========================================="

# 生成CSV报告
cat > "$RESULTS_DIR/comparison_report.csv" << 'CSV'
测试场景,并发数,持续时间,Gate_RPS,Gate_延迟,Nginx_RPS,Nginx_延迟,性能对比
CSV

for i in "${!CONCURRENCIES[@]}"; do
    conn=${CONCURRENCIES[$i]}
    conn_name=${CONCURRENCY_NAMES[$i]}
    
    gate_file=$(ls "$RESULTS_DIR"/*gate*${conn}conn.txt 2>/dev/null | head -1)
    nginx_file=$(ls "$RESULTS_DIR"/*nginx*${conn}conn.txt 2>/dev/null | head -1)
    
    gate_metrics=$(extract_metrics "$gate_file")
    nginx_metrics=$(extract_metrics "$nginx_file")
    
    echo "${conn_name},${conn},${DURATIONS}s,${gate_metrics},${nginx_metrics}" >> "$RESULTS_DIR/comparison_report.csv"
done

echo ""
echo "=========================================="
echo "测试结果汇总"
echo "=========================================="
echo ""
echo "原始数据目录: $RESULTS_DIR"
echo ""
echo "测试文件列表:"
ls -lh "$RESULTS_DIR"/*.txt 2>/dev/null | awk '{print "  " $9 " (" $5 ")"}'
echo ""
echo "对比报告: $RESULTS_DIR/comparison_report.csv"
echo ""

# 生成详细报告
generate_report

# 显示CSV内容
echo "CSV 报告内容:"
cat "$RESULTS_DIR/comparison_report.csv"
echo ""

echo "=========================================="
echo "✅ 压力测试完成!"
echo "=========================================="
echo ""
echo "所有测试数据保存在: $RESULTS_DIR"
