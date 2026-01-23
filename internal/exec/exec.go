package exec

import (
	"context"
	"fmt"
	"net"
	"os"
	"os/exec"
	"time"

	"github.com/ahaooahaz/jumpto/internal/record"
	"golang.org/x/crypto/ssh"
	"golang.org/x/sys/unix"
)

func TryConnect(ctx context.Context, record record.Record) (err error) {
	ctx2, cancel := context.WithTimeout(ctx, 5*time.Second)
	defer cancel()
	cfg := &ssh.ClientConfig{
		User: record.Username,
		Auth: []ssh.AuthMethod{
			ssh.Password(record.Password),
		},
		HostKeyCallback: ssh.InsecureIgnoreHostKey(),
		Timeout:         5 * time.Second,
	}

	addr := fmt.Sprintf("%s:%d", record.Host, record.Port)

	dialer := net.Dialer{}
	conn, err := dialer.DialContext(ctx2, "tcp", addr)
	if err != nil {
		return fmt.Errorf("dial failed: %v", err)
	}
	go func() {
		<-ctx2.Done()
		_ = conn.Close()
	}()

	c, _, _, err := ssh.NewClientConn(conn, addr, cfg)
	if err != nil {
		return err
	}
	defer c.Close()

	return nil
}

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

	return unix.Exec(sshpassPath, args, os.Environ())
}
