package main

import (
	"database/sql"
	"net/http"
	"time"
)

// handleSummaryCost godoc
// @summary Summary cost
// @description Calculate summary cost for specific time interval optionally
// @description filtering by user_id and/or subscription name
// @tags    subscription,summary cost
// @produce json
// @param   from         query string true                 "start of the interval"
// @param   to           query string true                 "end of the interval (exclusive)"
// @param   user_id      query string false                "user ID to filter by"
// @param   service_name query string false                "subscription ID to filter by"
// @success 200     {object} main.handleSummaryCost.result "calculated summary"
// @failure 400     {object} main.ErrorResult
// @failure 500     {object} main.ErrorResult
// @router /subscriptions_summary_cost [get]
func handleSummaryCost(w http.ResponseWriter, r *http.Request) {
	fromStr := r.URL.Query().Get("from")
	toStr := r.URL.Query().Get("to")
	userIDParam := r.URL.Query().Get("user_id")
	serviceNameParam := r.URL.Query().Get("service_name")

	if fromStr == "" || toStr == "" {
		respondError(w, http.StatusBadRequest, "`from` and `to` query parameters are required")
		return
	}

	from, err := time.Parse(MONTH_YEAR_LAYOUT, fromStr)
	if err != nil {
		respondError(w, http.StatusBadRequest, "invalid `from` value, expected MM-YYYY")
		return
	}

	to, err := time.Parse(MONTH_YEAR_LAYOUT, toStr)
	if err != nil {
		respondError(w, http.StatusBadRequest, "invalid `to` value, expected MM-YYYY")
		return
	}

	var userID sql.NullString
	var serviceName sql.NullString
	if userIDParam != "" {
		if !validateUUID(userIDParam) {
			respondError(w, http.StatusBadRequest, "`user_id` has invalid format")
			return
		} else {
			userID = sql.NullString{String: userIDParam, Valid: true}
		}
	}
	if serviceNameParam != "" {
		serviceName = sql.NullString{String: serviceNameParam, Valid: true}
	}

	// NOTE:
	// Здесь я не очень понял, что значит «суммарная стоимость всех подписок за
	// выбранный период»: нужна ли просто сумма цен всех подписок, начавшихся
	// в определённый период или пересекающихся с ним, или сумма всех денег,
	// которые пользователи должны заплатить за этот период (т.е. пересечение
	// с умножением на количество месяцев в периоде).
	//
	// Склонился ко второму варианту, т.к. он по-моему имеет больший смысл с
	// практической точки зрения.

	var summaryCost int

	err = db.QueryRow(`
		SELECT COALESCE(SUM(s.price * months.months), 0) AS total_amount
		FROM subscriptions s
		CROSS JOIN LATERAL (
			SELECT
				GREATEST(s.start_date, $1::DATE) AS overlap_start,
				LEAST(
					COALESCE(s.end_date, 'infinity'::DATE),
					$2::DATE
				) AS overlap_end
		) overlap
		CROSS JOIN LATERAL (
			SELECT
				(EXTRACT(YEAR FROM overlap.overlap_end) * 12 + EXTRACT(MONTH FROM overlap.overlap_end)) -
				(EXTRACT(YEAR FROM overlap.overlap_start) * 12 + EXTRACT(MONTH FROM overlap.overlap_start))
				AS months
		) months
		WHERE overlap.overlap_start < overlap.overlap_end
		  AND ($3::UUID IS NULL OR s.user_id = $3)
		  AND ($4::TEXT IS NULL OR s.service_name = $4);
	`, from, to, userID, serviceName).Scan(&summaryCost)
	if err != nil {
		respondError(w, http.StatusInternalServerError, "error calculating summary cost on SQL side: "+err.Error())
		return
	}

	type result struct {
		Status string `json:"status" example:"ok"`
		Result int    `json:"result" example:"4000"`
	}
	respondJSON(w, http.StatusOK, result{Status: "ok", Result: summaryCost})
}
