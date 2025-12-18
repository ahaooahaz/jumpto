package run

import (
	"context"
	"fmt"
	"os"

	"github.com/ahaooahaz/jumpto/internal/args"
	"github.com/ahaooahaz/jumpto/internal/record"
	"github.com/olekukonko/tablewriter"
	"github.com/olekukonko/tablewriter/tw"
)

func ListRun(ctx context.Context, gArgs args.ListArgs) {
	records, err := record.GetRecords()
	if err != nil {
		return
	}
	showRecords(ctx, records)
}

func showRecords(ctx context.Context, records record.Records) {
	var data [][]string
	for idx, r := range records {
		data = append(data, []string{fmt.Sprintf("%d", idx), r.Username, r.Host, fmt.Sprintf("%v", r.Port)})
	}
	table := tablewriter.NewTable(os.Stdout,
		// ref: https://github.com/olekukonko/tablewriter/issues/293
		tablewriter.WithEastAsian(tw.Off))
	table.Header("Index", "Username", "Host", "Port")
	table.Bulk(data)
	table.Render()
}
