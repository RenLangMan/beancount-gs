package service

import (
	"fmt"
	"os"
	"strings"
	"time"

	"cnb.cool/ysundy/bean/beancount-gs/script"
	"github.com/gin-gonic/gin"
)

func QueryLedgerSourceFileDir(c *gin.Context) {
	ledgerConfig := script.GetLedgerConfigFromContext(c)
	allFiles, err := dirs(ledgerConfig.DataPath, ledgerConfig.DataPath)
	if err != nil {
		InternalError(c, err.Error())
		return
	}

	// 过滤只返回 .bean 和 .beancount 文件，排除特定目录
	filteredFiles := filterBeanFiles(allFiles)

	OK(c, filteredFiles)
}

// 过滤函数
func filterBeanFiles(files []string) []string {
	// 要排除的目录
	excludedDirs := []string{
		".git",
		"node_modules",
		".vscode",
		".idea",
		"tmp",
		"temp",
		"log",
		"logs",
		"cache",
		"__pycache__",
	}

	var beanFiles []string
	for _, file := range files {
		// 检查是否应该排除
		exclude := false
		for _, dir := range excludedDirs {
			// 检查是否在排除目录中
			if strings.Contains(file, "/"+dir+"/") ||
				strings.HasPrefix(file, dir+"/") ||
				file == dir {
				exclude = true
				break
			}
		}

		if exclude {
			continue
		}

		// 只保留 .bean 和 .beancount 文件
		if strings.HasSuffix(file, ".bean") || strings.HasSuffix(file, ".beancount") {
			beanFiles = append(beanFiles, file)
		}
	}

	return beanFiles
}

func dirs(parent string, dirPath string) ([]string, error) {
	result := make([]string, 0)
	rd, err := os.ReadDir(dirPath)
	if err != nil {
		return nil, err
	}

	for _, dir := range rd {
		parentDir := dirPath + "/" + dir.Name()
		if dir.IsDir() {
			// 跳过备份文件夹
			if dir.Name() == "bak" {
				continue
			}
			files, err := dirs(parent, parentDir)
			if err != nil {
				return nil, err
			}
			result = append(result, files...)
		} else {
			fmt.Println(parentDir)
			result = append(result, strings.ReplaceAll(parentDir, parent+"/", ""))
		}
	}
	return result, nil
}

func QueryLedgerSourceFileContent(c *gin.Context) {
	ledgerConfig := script.GetLedgerConfigFromContext(c)
	queryParams, err := script.GetQueryParams(c)
	if err != nil {
		InternalError(c, err.Error())
		return
	}
	if queryParams.Path == "" {
		BadRequest(c, "params must not be blank")
		return
	}
	bytes, err := script.ReadFile(ledgerConfig.DataPath + "/" + queryParams.Path)
	if err != nil {
		InternalError(c, err.Error())
		return
	}
	OK(c, string(bytes))
}

type UpdateSourceFileForm struct {
	Path    string `form:"path" binding:"required"`
	Content string `form:"content"`
}

func UpdateLedgerSourceFileContent(c *gin.Context) {
	ledgerConfig := script.GetLedgerConfigFromContext(c)

	var updateSourceFileForm UpdateSourceFileForm
	if err := c.ShouldBindJSON(&updateSourceFileForm); err != nil {
		BadRequest(c, err.Error())
		return
	}

	sourceFilePath := ledgerConfig.DataPath + "/" + updateSourceFileForm.Path
	targetFilePath := ledgerConfig.DataPath + "/bak/" + time.Now().Format("20060102150405") + "_" + strings.ReplaceAll(updateSourceFileForm.Path, "/", "_")
	// 备份数据
	if ledgerConfig.IsBak {
		err := script.CopyFile(sourceFilePath, targetFilePath)
		if err != nil {
			InternalError(c, err.Error())
			return
		}
	}

	err := script.WriteFile(sourceFilePath, updateSourceFileForm.Content)
	if err != nil {
		InternalError(c, err.Error())
		return
	}

	// 更新外币种源文件后，更新缓存
	if strings.Contains(updateSourceFileForm.Path, "currency.json") {
		err = script.LoadLedgerCurrencyMap(ledgerConfig)
		if err != nil {
			InternalError(c, err.Error())
			return
		}
	}

	OK(c, nil)
}
