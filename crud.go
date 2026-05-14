package main

import (
	"database/sql"
	"encoding/json"
	"net/http"
	"strconv"
	"time"
)

const MONTH_YEAR_LAYOUT string = "01-2006"

// handleCreateSubscription godoc
// @summary Create subscription
// @tags    subscription,create
// @accept  json
// @produce json
// @param   request body     main.SubscriptionCURequest true "new subscription data"
// @success 201     {object} main.Subscription               "created subscription"
// @failure 400     {object} main.ErrorResult
// @failure 500     {object} main.ErrorResult
// @router /subscriptions [post]
func handleCreateSubscription(w http.ResponseWriter, r *http.Request) {
	var req SubscriptionCURequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		respondError(w, http.StatusBadRequest, "invalid JSON: "+err.Error())
		return
	}

	if err := req.Validate(); err != nil {
		respondError(w, http.StatusBadRequest, err.Error())
		return
	}

	startDate, err := time.Parse(MONTH_YEAR_LAYOUT, *req.StartDate)
	if err != nil {
		respondError(w, http.StatusBadRequest, "invalid `start_date`, expected MM-YYYY")
		return
	}

	var endDate sql.NullTime
	if req.EndDate != nil {
		ed, err := time.Parse(MONTH_YEAR_LAYOUT, *req.EndDate)
		if err != nil {
			respondError(w, http.StatusBadRequest, "invalid `end_date`, expected MM-YYYY")
			return
		}
		endDate = sql.NullTime{Time: ed, Valid: true}
	}

	row := db.QueryRow(`
		INSERT INTO subscriptions (service_name, price, user_id, start_date, end_date)
		VALUES ($1, $2, $3, $4, $5)
		RETURNING id, service_name, price, user_id, start_date, end_date
	`, req.ServiceName, *req.Price, *req.UserID, startDate, endDate)

	sub, err := scanSubscription(row)
	if err != nil {
		respondError(w, http.StatusInternalServerError, "failed to create subscription: "+err.Error())
		return
	}

	respondJSON(w, http.StatusCreated, sub)
}

// handleGetSubscription godoc
// @summary Read (get) subscription
// @tags    subscription,read
// @produce json
// @param   id      path     int                        true "subscription id"
// @success 200     {object} main.Subscription               "subscription"
// @failure 400     {object} main.ErrorResult
// @failure 404     {object} main.ErrorResult
// @failure 500     {object} main.ErrorResult
// @router /subscriptions/{id} [get]
func handleGetSubscription(w http.ResponseWriter, r *http.Request) {
	id, err := strconv.Atoi(r.PathValue("id"))
	if err != nil {
		respondError(w, http.StatusBadRequest, "invalid subscription id")
		return
	}

	row := db.QueryRow(`
		SELECT id, service_name, price, user_id, start_date, end_date
		FROM subscriptions
		WHERE id = $1
	`, id)

	sub, err := scanSubscription(row)
	if err == sql.ErrNoRows {
		respondError(w, http.StatusNotFound, "subscription not found")
		return
	}
	if err != nil {
		respondError(w, http.StatusInternalServerError, "failed to get subscription: "+err.Error())
		return
	}

	respondJSON(w, http.StatusOK, sub)
}

// handleUpdateSubscription godoc
// @summary Update (put) subscription
// @tags    subscription,update
// @accept  json
// @produce json
// @param   id      path     int                        true "subscription id"
// @param   request body     main.SubscriptionCURequest true "new subscription data"
// @success 200     {object} main.Subscription               "subscription"
// @failure 400     {object} main.ErrorResult
// @failure 404     {object} main.ErrorResult
// @failure 500     {object} main.ErrorResult
// @router /subscriptions/{id} [put]
func handleUpdateSubscription(w http.ResponseWriter, r *http.Request) {
	id, err := strconv.Atoi(r.PathValue("id"))
	if err != nil {
		respondError(w, http.StatusBadRequest, "invalid subscription id")
		return
	}

	var req SubscriptionCURequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		respondError(w, http.StatusBadRequest, "invalid JSON: "+err.Error())
		return
	}

	if err := req.Validate(); err != nil {
		respondError(w, http.StatusBadRequest, err.Error())
		return
	}

	startDate, err := time.Parse(MONTH_YEAR_LAYOUT, *req.StartDate)
	if err != nil {
		respondError(w, http.StatusBadRequest, "invalid `start_date`, expected MM-YYYY")
		return
	}

	var endDate sql.NullTime
	if req.EndDate != nil {
		ed, err := time.Parse(MONTH_YEAR_LAYOUT, *req.EndDate)
		if err != nil {
			respondError(w, http.StatusBadRequest, "invalid `end_date`, expected MM-YYYY")
			return
		}
		endDate = sql.NullTime{Time: ed, Valid: true}
	}

	row := db.QueryRow(`
		UPDATE subscriptions
		SET service_name = $2, price = $3, user_id = $4, start_date = $5, end_date = $6
		WHERE id = $1
		RETURNING id, service_name, price, user_id, start_date, end_date
	`, id, req.ServiceName, *req.Price, *req.UserID, startDate, endDate)

	sub, err := scanSubscription(row)
	if err == sql.ErrNoRows {
		respondError(w, http.StatusNotFound, "subscription not found")
		return
	}
	if err != nil {
		respondError(w, http.StatusInternalServerError, "failed to update subscription: "+err.Error())
		return
	}

	respondJSON(w, http.StatusOK, sub)
}

// handleDeleteSubscription godoc
// @summary Delete subscription
// @tags    subscription,delete
// @produce json
// @param   id      path     int                        true "subscription id"
// @success 204
// @failure 400     {object} main.ErrorResult
// @failure 404     {object} main.ErrorResult
// @failure 500     {object} main.ErrorResult
// @router /subscriptions/{id} [delete]
func handleDeleteSubscription(w http.ResponseWriter, r *http.Request) {
	id, err := strconv.Atoi(r.PathValue("id"))
	if err != nil {
		respondError(w, http.StatusBadRequest, "invalid subscription id")
		return
	}

	res, err := db.Exec(`DELETE FROM subscriptions WHERE id = $1`, id)
	if err != nil {
		respondError(w, http.StatusInternalServerError, "failed to delete subscription: "+err.Error())
		return
	}

	rowsAffected, _ := res.RowsAffected()
	if rowsAffected == 0 {
		respondError(w, http.StatusNotFound, "subscription not found")
		return
	}

	w.WriteHeader(http.StatusNoContent)
}

// handleListSubscriptions godoc
// @summary List subscription
// @tags    subscription,list
// @produce json
// @param   offset  query    int               false "offset from where to list" default(0)
// @param   limit   query    int               false "maximum count to list"     default(100)
// @success 200     {array}  main.Subscription       "subscriptions"
// @failure 500     {object} main.ErrorResult
// @router /subscriptions [get]
func handleListSubscriptions(w http.ResponseWriter, r *http.Request) {
	offsetStr := r.URL.Query().Get("offset")
	limitStr := r.URL.Query().Get("limit")

	offset := 0
	limit := 100

	if offsetStr != "" {
		if o, err := strconv.Atoi(offsetStr); err == nil && o >= 0 {
			offset = o
		}
	}
	if limitStr != "" {
		if l, err := strconv.Atoi(limitStr); err == nil && l > 0 {
			limit = l
		}
	}

	rows, err := db.Query(`
		SELECT id, service_name, price, user_id, start_date, end_date
		FROM subscriptions
		ORDER BY id
		OFFSET $1 LIMIT $2
	`, offset, limit)
	if err != nil {
		respondError(w, http.StatusInternalServerError, "failed to list subscriptions: "+err.Error())
		return
	}
	defer rows.Close()

	subs := make([]*Subscription, 0, limit)
	for rows.Next() {
		sub, err := scanSubscription(rows)
		if err != nil {
			respondError(w, http.StatusInternalServerError, "failed to scan subscription: "+err.Error())
			return
		}
		subs = append(subs, sub)
	}
	if err := rows.Err(); err != nil {
		respondError(w, http.StatusInternalServerError, "error iterating rows: "+err.Error())
		return
	}

	respondJSON(w, http.StatusOK, subs)
}
