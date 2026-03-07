package clipboard

import (
	"sync"
	"time"
)

type ItemType int

const (
	TypeText  ItemType = iota
	TypeImage
)

type ClipboardItem struct {
	ID        int
	Type      ItemType
	TextData  string
	ImageData []byte
	Preview   string // 文字前 100 字或圖片尺寸
	CopiedAt  time.Time
}

type Storage struct {
	mu       sync.RWMutex
	items    []ClipboardItem
	maxItems int
	nextID   int
}

func NewStorage(maxItems int) *Storage {
	return &Storage{
		items:    make([]ClipboardItem, 0, maxItems),
		maxItems: maxItems,
		nextID:   1,
	}
}

func (s *Storage) Add(item ClipboardItem) {
	s.mu.Lock()
	defer s.mu.Unlock()

	item.ID = s.nextID
	s.nextID++
	item.CopiedAt = time.Now()

	// Prepend (newest first)
	s.items = append([]ClipboardItem{item}, s.items...)

	// Trim to max
	if len(s.items) > s.maxItems {
		s.items = s.items[:s.maxItems]
	}
}

func (s *Storage) GetAll() []ClipboardItem {
	s.mu.RLock()
	defer s.mu.RUnlock()
	result := make([]ClipboardItem, len(s.items))
	copy(result, s.items)
	return result
}

func (s *Storage) Get(index int) (ClipboardItem, bool) {
	s.mu.RLock()
	defer s.mu.RUnlock()
	if index < 0 || index >= len(s.items) {
		return ClipboardItem{}, false
	}
	return s.items[index], true
}

func (s *Storage) Clear() {
	s.mu.Lock()
	defer s.mu.Unlock()
	s.items = s.items[:0]
}

func (s *Storage) Count() int {
	s.mu.RLock()
	defer s.mu.RUnlock()
	return len(s.items)
}
