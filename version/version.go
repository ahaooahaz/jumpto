package version

import "fmt"

var (
	BuildID = "None"
	BuildTS = "None"
	GitHash = "None"
	Version = "None"
)

func GetVersion() string {
	if GitHash != "None" {
		h := GitHash
		if len(h) > 7 {
			h = h[:7]
		}
		return fmt.Sprintf("%s-%s", Version, h)
	}
	return Version
}

func PrintFullVersionInfo() {
	fmt.Println("Version:          ", GetVersion())
	fmt.Println("Git Commit:       ", GitHash)
	fmt.Println("Build Time:       ", BuildTS)
	fmt.Println("Build ID:         ", BuildID)
}
