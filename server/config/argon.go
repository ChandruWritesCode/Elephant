package config

import (
	"strconv"

	"github.com/commandlinecoding/elephant/server/env"
)

type ArgonConfig struct {
	Memory      uint32
	Iterations  uint32
	Parallelism uint8
	SaltLength  uint32
	KeyLength   uint32
}

var Argon ArgonConfig

func init() {
	mem, _ := strconv.ParseUint(env.ARGON_MEMORY, 10, 32)
	iter, _ := strconv.ParseUint(env.ARGON_ITERATIONS, 10, 32)
	par, _ := strconv.ParseUint(env.ARGON_PARALLELISM, 10, 8)

	Argon = ArgonConfig{
		Memory:      uint32(mem),
		Iterations:  uint32(iter),
		Parallelism: uint8(par),
		SaltLength:  16,
		KeyLength:   32,
	}
}