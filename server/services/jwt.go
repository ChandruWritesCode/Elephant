package services

import (
	"fmt"
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

// VerifyAccessToken
func VerifyAccessToken(tokenStr string) (string, error) {
	token, err := jwt.Parse(tokenStr, func(token *jwt.Token) (interface{}, error) {
		if _, ok := token.Method.(*jwt.SigningMethodHMAC); !ok {
			return nil, fmt.Errorf("unexpected signing method: %v", token.Header["alg"])
		}
		return []byte(env.JWT_SECRET), nil
	})

	if err != nil {
		return "", err
	}

	if claims, ok := token.Claims.(jwt.MapClaims); ok && token.Valid {
		uid, ok := claims["sub"].(string)
		if !ok {
			return "", fmt.Errorf("invalid token claim structure")
		}
		return uid, nil
	}

	return "", fmt.Errorf("invalid token status")
}
