package dos

import (
	"path/filepath"
	"strings"
)

// Expand filenames matching with wildcard-pattern.
func Glob(pattern string) ([]string, error) {
	pname := filepath.Base(pattern)
	if strings.IndexAny(pname, "*?") < 0 {
		return nil, nil
	}
	match := make([]string, 0, 100)
	dirname := filepath.Dir(pattern)
	err := ForFiles(pattern, func(findf *FileInfo) bool {
		name := findf.Name()
		if (name[0] != '.' || pname[0] == '.') && !findf.IsHidden() {
			match = append(match, filepath.Join(dirname, name))
		}
		return true
	})
	return match, err
}
