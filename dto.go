package main

import (
	"errors"
	"strings"
)

type ErrorResult struct {
	Status  string `json:"status" example:"error"`
	Message string `json:"message" example:"invalid start_date, expected MM-YYYY"`
}

type Subscription struct {
	ID          int     `json:"id" example:"1"`
	ServiceName string  `json:"service_name" example:"Yandex Plus"`
	Price       int     `json:"price" example:"400"`
	UserID      string  `json:"user_id" example:"60601fee-2bf1-4721-ae6f-7636e79a0cba"`
	StartDate   string  `json:"start_date" example:"07-2025"`
	EndDate     *string `json:"end_date,omitempty" example:"05-2026"`
}

type SubscriptionCURequest struct {
	ServiceName string  `json:"service_name" example:"Yandex Plus"`
	Price       *int    `json:"price" example:"400"`
	UserID      *string `json:"user_id" example:"60601fee-2bf1-4721-ae6f-7636e79a0cba"`
	StartDate   *string `json:"start_date" example:"07-2025"`
	EndDate     *string `json:"end_date,omitempty" example:"05-2026"`
}

// Validates everything but date format.
func (r *SubscriptionCURequest) Validate() error {
	if strings.TrimSpace(r.ServiceName) == "" {
		return errors.New("`service_name` is required")
	}
	if r.Price == nil {
		return errors.New("`price` is required")
	}
	if r.UserID == nil {
		return errors.New("`user_id` is required")
	}
	if r.StartDate == nil {
		return errors.New("`start_date` is required")
	}

	if *r.Price < 0 {
		return errors.New("negative price is not allowed")
	}
	if !validateUUID(*r.UserID) {
		return errors.New("`user_id` has invalid format")
	}

	return nil
}

func validateUUID(uuid string) bool {
	hasOpening := strings.HasPrefix(uuid, "{")
	hasClosing := strings.HasSuffix(uuid, "}")
	if hasOpening != hasClosing {
		return false
	}
	if hasOpening {
		uuid = uuid[1 : len(uuid)-1]
	}
	cleaned := strings.ReplaceAll(uuid, "-", "")
	if len(cleaned) != 32 {
		return false
	}
	for _, ch := range cleaned {
		if !((ch >= '0' && ch <= '9') ||
			(ch >= 'a' && ch <= 'f') ||
			(ch >= 'A' && ch <= 'F')) {
			return false
		}
	}
	return true
}
