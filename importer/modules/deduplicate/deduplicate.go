package deduplicate

import (
	"sync"
	"time"
)

// Deduplicator 负责检测和处理重复交易
type Deduplicator struct {
	mu      sync.Mutex
	entries map[string]time.Time
}

// NewDeduplicator 创建新的去重器实例
func NewDeduplicator() *Deduplicator {
	return &Deduplicator{
		entries: make(map[string]time.Time),
	}
}

// CheckAndAdd 检查交易是否重复，如果没有则添加
func (d *Deduplicator) CheckAndAdd(txID string, txTime time.Time) bool {
	d.mu.Lock()
	defer d.mu.Unlock()

	// 检查交易ID是否存在
	if existingTime, exists := d.entries[txID]; exists {
		// 如果时间戳也匹配，则是重复交易
		return existingTime.Equal(txTime)
	}

	// 添加新交易
	d.entries[txID] = txTime
	return false
}

// LoadFromFile 从文件加载检查点
func (d *Deduplicator) LoadFromFile(filePath string) error {
	d.mu.Lock()
	defer d.mu.Unlock()

	// TODO: 实现从文件加载检查点
	return nil
}

// SaveToFile 保存检查点到文件
func (d *Deduplicator) SaveToFile(filePath string) error {
	d.mu.Lock()
	defer d.mu.Unlock()

	// TODO: 实现保存检查点到文件
	return nil
}

// Size 返回当前跟踪的交易数量
func (d *Deduplicator) Size() int {
	d.mu.Lock()
	defer d.mu.Unlock()
	return len(d.entries)
}

// Clear 清除所有记录
func (d *Deduplicator) Clear() {
	d.mu.Lock()
	defer d.mu.Unlock()
	d.entries = make(map[string]time.Time)
}
