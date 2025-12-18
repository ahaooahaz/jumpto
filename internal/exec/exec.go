package exec

import (
	"context"
	"fmt"
	"log"
	"os"
	"os/exec"

	"github.com/ahaooahaz/jumpto/internal/record"
	"golang.org/x/sys/unix"
)

func Connect(ctx context.Context, record record.Record) (err error) {
	var sshpassPath string
	sshpassPath, err = exec.LookPath("sshpass")
	if err != nil {
		return
	}

	args := []string{
		"sshpass", "-p", record.Password,
		"ssh",
		"-p", fmt.Sprintf("%d", record.Port),
		fmt.Sprintf("%s@%s", record.Username, record.Host),
	}

	err = unix.Exec(sshpassPath, args, os.Environ())
	if err != nil {
		log.Fatalf("exec ssh failed: %v", err)
	}
	return
}
