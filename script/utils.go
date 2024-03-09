package script

import (
	"bytes"
	"math/rand"
	"net"
	"time"
)

func GetIpAddress() string {
	addrs, _ := net.InterfaceAddrs()
	for _, value := range addrs {
		if ipnet, ok := value.(*net.IPNet); ok && !ipnet.IP.IsLoopback() {
			if ipnet.IP.To4() != nil {
				return ipnet.IP.String()
			}
		}
	}
	return ""
}

const char = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"

func RandChar(size int) string {
	source := rand.NewSource(time.Now().UnixNano()) // 产生随机种子
	var s bytes.Buffer
	for i := 0; i < size; i++ {
		s.WriteByte(char[source.Int63()%int64(len(char))])
	}
	return s.String()
}

func getTimeStamp(str_date string) Timestamp {
	time_layout := "2006-01-02 15:04:05"
	if len(str_date) == 10 {
		//time_layout = "2006-01-02"
		str_date = str_date + " 00:00:00"
	}
	// 获取时区
	loc, err := time.LoadLocation("Local")
	if err != nil {
		return 0
	}
	// 转换为时间戳
	the_time, err := time.ParseInLocation(time_layout, str_date, loc)
	if err != nil {
		return 0
	}
	// 返回时间戳
	return Timestamp(the_time.Unix())
}

type Timestamp int64

func MaxTimestamp(t1, t2 Timestamp) string {
	// 假设t1和t2是Timestamp类型的变量
	// 返回较大的那个时间戳
	// 这里只是简单地比较了两个时间戳的大小，实际应用中可能需要更复杂的逻辑
	time_layout := "2006-01-02"
	if t1 == 0 {
		LogSystemInfo("Error: t1 is zero")
		return "Error: t1 is zero"

	}
	if t2 == 0 {
		LogSystemInfo("Error: t2 is zero")
		return "Error: t2 is zero"

	}
	if t1 > t2 {
		return time.Unix(int64(t1), 0).Format(time_layout)
	} else {
		return time.Unix(int64(t2), 0).Format(time_layout)
	}
}

func MinTimestamp(t1, t2 Timestamp) string {
	// 假设t1和t2是Timestamp类型的变量
	// 返回较小的那个时间戳
	// 这里只是简单地比较了两个时间戳的大小，实际应用中可能需要更复杂的逻辑
	time_layout := "2006-01-02"
	if t1 == 0 {
		LogSystemInfo("Error: t1 is zero")
		return "Error: t1 is zero"

	}
	if t2 == 0 {
		LogSystemInfo("Error: t2 is zero")
		return "Error: t2 is zero"

	}
	if t1 < t2 {
		return time.Unix(int64(t1), 0).Format(time_layout)
	} else {
		return time.Unix(int64(t2), 0).Format(time_layout)
	}
}
