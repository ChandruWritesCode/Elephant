package services

import (
	"time"

	"github.com/commandlinecoding/elephant/server/env"
	"github.com/golang-jwt/jwt/v5"
)

type TokenPair struct {
	AccessToken  string `json:"access_token"`
	RefreshToken string `json:"refresh_token"`
}

func GenerateTokenPair(uid string) (*TokenPair, error) {
	// Access Token - 15 Minute Window
	atkClaims := jwt.MapClaims{
		"sub": uid,
		"exp": time.Now().Add(15 * time.Minute).Unix(),
		"iat": time.Now().Unix(),
	}
	atk := jwt.NewWithClaims(jwt.SigningMethodHS256, atkClaims)
	atkStr, err := atk.SignedString([]byte(env.JWT_SECRET))
	if err != nil {
		return nil, err
	}

	// Refresh Token - 7 Day Lifespan
	rtkClaims := jwt.MapClaims{
		"sub": uid,
		"exp": time.Now().Add(7 * 24 * time.Hour).Unix(),
		"iat": time.Now().Unix(),
	}
	rtk := jwt.NewWithClaims(jwt.SigningMethodHS256, rtkClaims)
	rtkStr, err := rtk.SignedString([]byte(env.JWT_SECRET))
	if err != nil {
		return nil, err
	}

	return &TokenPair{
		AccessToken:  atkStr,
		RefreshToken: rtkStr,
	}, nil
}
