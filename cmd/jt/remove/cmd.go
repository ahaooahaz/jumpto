package remove

import (
	"github.com/ahaooahaz/jumpto/internal/args"
	"github.com/ahaooahaz/jumpto/internal/run"
	"github.com/spf13/cobra"
)

var gArgs args.RemoveArgs
var Cmd = &cobra.Command{
	Use:   "remove",
	Short: "remove remote machine",
	RunE: func(cmd *cobra.Command, args []string) (err error) {
		err = run.RemoveRun(cmd.Context(), gArgs)
		return
	},
}
