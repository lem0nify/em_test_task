package main

import (
	"database/sql"
	"encoding/json"
	"net/http"
	"time"
)

func respondJSON(w http.ResponseWriter, status int, data any) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(status)
	if data != nil {
		json.NewEncoder(w).Encode(data)
	}
}

func respondError(w http.ResponseWriter, status int, msg string) {
	respondJSON(w, status, ErrorResult{Status: "error", Message: msg})
}

type Scannable interface {
	Scan(dest ...any) error
}

func scanSubscription(row Scannable) (*Subscription, error) {
	var sub Subscription
	var startDate time.Time
	var endDate sql.NullTime

	err := row.Scan(&sub.ID, &sub.ServiceName, &sub.Price, &sub.UserID, &startDate, &endDate)
	if err != nil {
		return nil, err
	}

	sub.StartDate = startDate.Format(MONTH_YEAR_LAYOUT)
	if endDate.Valid {
		ed := endDate.Time.Format(MONTH_YEAR_LAYOUT)
		sub.EndDate = &ed
	}

	return &sub, nil
}
