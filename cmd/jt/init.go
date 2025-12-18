package main

import (
	"github.com/sirupsen/logrus"
)

func init() {
	err := initEnv()
	if err != nil {
		panic(err.Error())
	}
}

func initEnv() (err error) {
	logrus.SetLevel(logrus.DebugLevel)
	logrus.SetReportCaller(true)
	logrus.SetFormatter(&CustomFormatter{})
	return
}

type CustomFormatter struct{}

func (f *CustomFormatter) Format(entry *logrus.Entry) ([]byte, error) {
	var color string
	reset := "\033[0m"

	switch entry.Level {
	case logrus.InfoLevel:
		color = "\033[32m"
	case logrus.WarnLevel:
		color = "\033[33m"
	case logrus.ErrorLevel, logrus.FatalLevel, logrus.PanicLevel:
		color = "\033[31m"
	default:
		color = ""
	}

	return []byte(color + entry.Message + reset + "\n"), nil
}
