package run

import (
	"context"
	"fmt"
	"os"
	"strings"

	"github.com/ahaooahaz/jumpto/internal/args"
	"github.com/ahaooahaz/jumpto/internal/exec"
	"github.com/ahaooahaz/jumpto/internal/record"
	"github.com/sirupsen/logrus"
	"golang.org/x/term"
)

func RootRun(ctx context.Context, gArgs args.RootArgs) (err error) {
	r := &record.Record{}
	if strings.Contains(gArgs.Target, `@`) {
		strs := strings.Split(gArgs.Target, `@`)
		if len(strs) != 2 {
			err = fmt.Errorf("invalid target")
			return
		}
		r.Username = strs[0]
		r.Host = strs[1]
		r.Port = gArgs.Port
		logrus.Debug("username: ", r.Username, " host: ", r.Host, " port: ", r.Port)
		rd, ine := record.GetRecordByUHP(r.Username, r.Host, r.Port)
		if ine != nil {
			fmt.Print("tell me your password: ")
			var passwordBytes []byte
			passwordBytes, err = term.ReadPassword(int(os.Stdin.Fd()))
			fmt.Println()
			if err != nil {
				return
			}

			r.Password = string(passwordBytes)
			err = record.CreateRecord(*r)
			if err != nil {
				return
			}
		} else {
			r = rd
		}
	} else {

		// match hosts
		var rds, matchedRecords record.Records
		rds, err = record.GetRecords()
		if err != nil {
			return
		}

		for _, rd := range rds {
			if strings.Contains(rd.Host, gArgs.Target) {
				matchedRecords = append(matchedRecords, rd)
			}
		}

		if len(matchedRecords) == 1 {
			r = &matchedRecords[0]
		} else if len(matchedRecords) == 0 {
			logrus.Error("no records")
			return
		} else {
			showRecords(ctx, matchedRecords)
			var index int
			fmt.Print("choose index: ")
			_, err = fmt.Scan(&index)
			if err != nil {
				return
			}

			r = &matchedRecords[index]
		}
	}

	err = exec.Connect(ctx, *r)
	if err != nil {
		return
	}
	return
}
