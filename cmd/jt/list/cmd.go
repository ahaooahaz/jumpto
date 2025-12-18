package list

import (
	"github.com/ahaooahaz/jumpto/internal/args"
	"github.com/ahaooahaz/jumpto/internal/run"
	"github.com/spf13/cobra"
)

var Cmd = &cobra.Command{
	Use:   "list",
	Short: "list remote machine",
	Run: func(cmd *cobra.Command, args []string) {
		run.ListRun(cmd.Context(), gArgs)
	},
}

var gArgs args.ListArgs
