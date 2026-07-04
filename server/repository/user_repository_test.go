package repository

import (
	"context"
	"testing"

	"github.com/commandlinecoding/elephant/server/config"
)

func TestUserRepository_create_and_search(t *testing.T) {
	ctx := context.Background()

	if config.DB == nil {
		t.Fatal("Config.DB not intialized. Run your container setup environment first.")
	}

	repo:=NewUserRepository()

	testUsername:="testusername"
	testDisplayName:="testuser"
	testHash:="$argon2id$v=19$m=65536,t=3,p=4$mockhashvalue"

	t.Cleanup(func() {
		cleanupQuery:= "DELETE FROM users WHERE username=$1;"
		_, err := config.DB.Exec(ctx, cleanupQuery, testUsername)
		if err != nil {
			t.Logf("cleanup failed %v",err)
		}
	})

	user, err := repo.CreateUser(ctx, testUsername, testDisplayName, testHash)
	if err != nil {
		t.Fatalf("Create User failed: %v", err)
	}

	if user.Username == "" {
		t.Errorf("expected a username, but is blank")
	}

	if user.DisplayName != testDisplayName {
		t.Errorf("expected display_name %q, got %q",testDisplayName,user.DisplayName)
	}

	if user.ID == "" {
		t.Error("Expected UUID string to be populated, but ID is blank")
	}

	searchResults, err := repo.SearchUsers(ctx, user.Username, 10, 0)
	if err != nil {
		t.Errorf("SearchUsers failed: %v", err)
	}

	if len(searchResults) == 0 {
		t.Errorf("Created user %q not found in search results", user.Username)
	}

}
