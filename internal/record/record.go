package record

import (
	"encoding/json"
	"os"
	"path/filepath"
	"sync"

	"github.com/go-gormigrate/gormigrate/v2"
	"github.com/sirupsen/logrus"
	"gorm.io/driver/sqlite"
	"gorm.io/gorm"
)

type Records []Record

var recordPath = os.Getenv("HOME") + "/.config/jt/records.db"
var once sync.Once
var _records Records
var _db *gorm.DB

type Record struct {
	gorm.Model
	Username    string `json:"username" gorm:"type:text;not null"`
	Host        string `json:"host" gorm:"type:text;not null"`
	Password    string `json:"password" gorm:"type:text;not null"`
	Port        uint16 `json:"port" gorm:"not null"`
	ActiveTimes uint64 `json:"connect_count" gorm:"not null;default:0"`
}

func instance() *gorm.DB {
	once.Do(func() {
		var err error
		_db, err = gorm.Open(sqlite.Open(recordPath), &gorm.Config{})
		if err != nil {
			logrus.Fatal(err.Error())
		}

		migrate := gormigrate.New(_db, gormigrate.DefaultOptions, []*gormigrate.Migration{
			{
				ID: "202601121703",
				Migrate: func(tx *gorm.DB) error {
					var ine error
					ine = tx.AutoMigrate(&Record{})
					if ine != nil {
						logrus.Fatal(ine.Error())
					}

					oldRecordFile := filepath.Dir(recordPath) + "/records.json"
					var stat os.FileInfo
					stat, ine = os.Stat(oldRecordFile)
					if ine == nil {
						if !stat.IsDir() {
							var raw []byte
							raw, ine = os.ReadFile(oldRecordFile)
							if ine != nil {
								logrus.Fatal(ine.Error())
							}
							var records Records
							ine = json.Unmarshal(raw, &records)
							if ine != nil {
								logrus.Fatal(ine.Error())
							}
							for _, r := range records {
								err = tx.Create(&r).Error
								if err != nil {
									logrus.Fatal(err.Error())
								}
							}
						}
					}
					return nil
				},
				Rollback: func(tx *gorm.DB) error {
					return tx.Migrator().DropTable("records")
				},
			},
		})

		err = migrate.Migrate()
		if err != nil {
			logrus.Fatal(err.Error())
		}
	})
	return _db
}

func GetRecords() (records Records, err error) {
	err = instance().Find(&records).Error
	return
}

func CreateRecord(record Record) (err error) {
	err = instance().Create(&record).Error
	return
}

func RemoveRecord(ID uint) (err error) {
	err = instance().Unscoped().Delete(&Record{}, ID).Error
	return
}

func GetRecordByUHP(username, host string, port uint16) (record *Record, err error) {
	err = instance().Where("username = ? AND host = ? AND port = ?", username, host, port).First(&record).Error
	return
}
