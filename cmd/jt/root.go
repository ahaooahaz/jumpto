package main

import (
	"fmt"
	"os"

	"github.com/ahaooahaz/jumpto/cmd/jt/list"
	"github.com/ahaooahaz/jumpto/cmd/jt/remove"
	"github.com/ahaooahaz/jumpto/cmd/jt/version"
	"github.com/ahaooahaz/jumpto/internal/args"
	"github.com/ahaooahaz/jumpto/internal/run"
	"github.com/sirupsen/logrus"
	"github.com/spf13/cobra"
)

func init() {
	rootCmd.AddCommand(list.Cmd)
	rootCmd.AddCommand(remove.Cmd)
	rootCmd.AddCommand(version.Cmd)

	rootCmd.PersistentFlags().Uint16VarP(&gArgs.Port, "port", "P", 22, "ssh port")
}

var gArgs args.RootArgs

var rootCmd = &cobra.Command{
	Use:           "jt",
	Short:         "jumpto",
	Long:          `jump to remote machine with ssh`,
	SilenceErrors: true,
	SilenceUsage:  true,
	Args:          cobra.MinimumNArgs(1),
	RunE: func(cmd *cobra.Command, args []string) (err error) {
		host := args[len(args)-1]
		gArgs.Target = host
		err = run.RootRun(cmd.Context(), gArgs)
		if err != nil {
			logrus.Fatal(err.Error())
		}
		return
	},
}

func Execute() {
	if err := rootCmd.Execute(); err != nil {
		fmt.Println(err)
		os.Exit(1)
	}
}
