package main

import (
	"context"
	"database/sql"
	"fmt"
	"log"
	"net"
	"net/http"
	"strconv"

	"github.com/joho/godotenv"
	"github.com/pressly/goose/v3"
	"github.com/sethvargo/go-envconfig"

	_ "github.com/jackc/pgx/v5/stdlib"
	_ "lem0nify.ru/em_test_task/docs"

	httpSwagger "github.com/swaggo/http-swagger"
)

type Config struct {
	Port             string `env:"SERVICE_PORT,default=8080"`
	DBHost           string `env:"DB_HOST,default=db"`
	PostgresUser     string `env:"POSTGRES_USER,required"`
	PostgresPassword string `env:"POSTGRES_PASSWORD,required"`
	PostgresDB       string `env:"POSTGRES_DB,default=test_task_db"`
}

var db *sql.DB

// @title Effective Mobile subscriptions API
// @version 0.1.0
// @license.name MIT
// @contact.name  Konstantin Chetenov
// @contact.email kchetenov@yandex.ru
func main() {
	ctx := context.Background()

	godotenv.Load()

	var config Config
	err := envconfig.Process(ctx, &config)
	if err != nil {
		log.Fatalln("error loading env vars:", err)
	}

	port, err := strconv.Atoi(config.Port)
	if err != nil || port < 0 || port > 65535 {
		log.Fatalln("port provided in SERVICE_PORT env variable is invalid u16 number")
	}

	dbConnString := fmt.Sprintf(
		"postgres://%s:%s@%s:5432/%s",
		config.PostgresUser,
		config.PostgresPassword,
		config.DBHost,
		config.PostgresDB,
	)

	// connect to db
	db, err = sql.Open("pgx", dbConnString)
	if err != nil {
		log.Fatalln("error connecting to database:", err)
	}
	defer db.Close()

	// apply migrations
	goose.SetDialect("postgres")
	err = goose.RunContext(ctx, "up", db, "migrations")
	if err != nil {
		log.Fatalln("error running migrations:", err)
	}

	// http
	mux := http.NewServeMux()
	mux.HandleFunc("POST /subscriptions", handleCreateSubscription)
	mux.HandleFunc("GET /subscriptions/{id}", handleGetSubscription)
	mux.HandleFunc("PUT /subscriptions/{id}", handleUpdateSubscription)
	mux.HandleFunc("DELETE /subscriptions/{id}", handleDeleteSubscription)
	mux.HandleFunc("GET /subscriptions", handleListSubscriptions)
	mux.HandleFunc("GET /subscriptions_summary_cost", handleSummaryCost)

	mux.Handle("/swagger/", httpSwagger.WrapHandler)

	loggingHandler := loggingMiddleware(mux)

	listener, err := net.Listen("tcp", fmt.Sprintf(":%d", port))
	if err != nil {
		log.Fatalf("error running server on port %d: %v\n", port, err)
	}

	log.Printf("the server is running on port %d\n", port)

	log.Fatal(http.Serve(listener, loggingHandler))
}
