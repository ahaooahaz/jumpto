package run

import (
	"context"
	"fmt"
	"strconv"

	"github.com/ahaooahaz/jumpto/internal/args"
	"github.com/ahaooahaz/jumpto/internal/record"
	"github.com/sirupsen/logrus"
)

func RemoveRun(ctx context.Context, gArgs args.RemoveArgs) (err error) {
	for {
		var records record.Records
		records, err = record.GetRecords()
		if err != nil {
			logrus.Error(err.Error())
			return
		}
		showRecords(ctx, records)
		var input string
		fmt.Print("choose index [q to quit]: ")
		_, err = fmt.Scan(&input)
		if err != nil {
			return
		}
		if input == "q" {
			break
		}

		index, err := strconv.Atoi(input)
		if err != nil {
			logrus.Error(err.Error())
			continue
		}

		err = record.RemoveRecord(records[index].ID)
		if err != nil {
			logrus.Error(err.Error())
			continue
		}
	}
	return
}
