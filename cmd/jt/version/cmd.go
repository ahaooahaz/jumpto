package version

import (
	"github.com/ahaooahaz/jumpto/version"
	"github.com/spf13/cobra"
)

var Cmd = &cobra.Command{
	Use:   "version",
	Short: "show version",
	Run: func(cmd *cobra.Command, args []string) {
		version.PrintFullVersionInfo()
	},
}
