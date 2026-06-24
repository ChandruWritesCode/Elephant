package repository

import (
	"context"

	"github.com/commandlinecoding/elephant/server/config"
	"github.com/commandlinecoding/elephant/server/models"
)

type GroupRepository struct{}

func NewGroupRepository() *GroupRepository {
	return &GroupRepository{}
}

func (r *GroupRepository) Create(ctx context.Context, name, creatorID string) (*models.Group, error) {
	query := `
		INSERT INTO groups (name, created_by)
		VALUES ($1, $2)
		RETURNING id, name, created_by, created_at;
	`
	var g models.Group
	err := config.DB.QueryRow(ctx, query, name, creatorID).Scan(&g.ID, &g.Name, &g.CreatedBy, &g.CreatedAt)
	if err != nil {
		return nil, err
	}

	joinQuery := `INSERT INTO group_members (group_id, user_id) VALUES ($1, $2);`
	_, err = config.DB.Exec(ctx, joinQuery, g.ID, creatorID)
	return &g, err
}

func (r *GroupRepository) GetGroupMembers(ctx context.Context, groupID string) ([]string, error) {
	query := `SELECT user_id FROM group_members WHERE group_id = $1;`
	rows, err := config.DB.Query(ctx, query, groupID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var userIDs []string
	for rows.Next() {
		var uid string
		if err := rows.Scan(&uid); err != nil {
			return nil, err
		}
		userIDs = append(userIDs, uid)
	}
	return userIDs, nil
}
