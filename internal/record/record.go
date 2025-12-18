package record

import (
	"encoding/json"
	"fmt"
	"os"
	"sync"
)

type Records []Record

var RecordJSONFilepath = os.Getenv("HOME") + "/.config/jt/records.json"
var once sync.Once
var _records Records

type Record struct {
	Username string `json:"username"`
	Host     string `json:"host"`
	Password string `json:"password"`
	Port     uint16 `json:"port"`
}

func GetRecords() (records Records, err error) {
	once.Do(func() {
		raw, ine := os.ReadFile(RecordJSONFilepath)
		if ine != nil {
			err = ine
			return
		}
		err = json.Unmarshal(raw, &_records)
		if err != nil {
			return
		}
	})
	records = _records
	return
}

func CreateRecord(record Record) (err error) {
	_records = append(_records, record)
	return saveRecords(RecordJSONFilepath, &_records)
}

func GetRecordByUHP(username, host string, port uint16) (record *Record, err error) {
	records, err := GetRecords()
	if err != nil {
		return
	}
	for _, r := range records {
		if r.Username == username && r.Host == host && r.Port == port {
			return &r, nil
		}
	}
	return nil, fmt.Errorf("not found")
}

func saveRecords(path string, records *Records) error {
	tmp := path + ".tmp"

	data, err := json.MarshalIndent(records, "", "  ")
	if err != nil {
		return err
	}

	if err := os.WriteFile(tmp, data, 0600); err != nil {
		return err
	}

	return os.Rename(tmp, path)
}
