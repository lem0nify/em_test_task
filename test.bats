#!/usr/bin/env bats

SERVICE_URL="http://localhost:8080"

@test "CREATE without service_name returns 400 Bad Request" {
    http_code=$(curl -s -X POST "$SERVICE_URL/subscriptions" \
        -o /dev/null \
        -H "Content-Type: application/json" \
        -d '{
                "price": 400,
                "user_id": "60601fee-2bf1-4721-ae6f-7636e79a0cba",
                "start_date": "07-2025"
            }' \
        -w '%{http_code}')

    [ "$http_code" -eq 400 ]
}

@test "CREATE without price returns 400 Bad Request" {
    http_code=$(curl -s -X POST "$SERVICE_URL/subscriptions" \
        -o /dev/null \
        -H "Content-Type: application/json" \
        -d '{
                "service_name": "Yandex Plus",
                "user_id": "60601fee-2bf1-4721-ae6f-7636e79a0cba",
                "start_date": "07-2025"
            }' \
        -w '%{http_code}')

    [ "$http_code" -eq 400 ]
}

@test "CREATE without user_id returns 400 Bad Request" {
    http_code=$(curl -s -X POST "$SERVICE_URL/subscriptions" \
        -o /dev/null \
        -H "Content-Type: application/json" \
        -d '{
                "service_name": "Yandex Plus",
                "price": 400,
                "start_date": "07-2025"
            }' \
        -w '%{http_code}')

    [ "$http_code" -eq 400 ]
}

@test "CREATE with incorrect user_id returns 400 Bad Request" {
    http_code=$(curl -s -X POST "$SERVICE_URL/subscriptions" \
        -o /dev/null \
        -H "Content-Type: application/json" \
        -d '{
                "service_name": "Yandex Plus",
                "price": 400,
                "user_id": "60601fee-2bf1-4721-ae6f-7636e79a0cba1",
                "start_date": "07-2025"
            }' \
        -w '%{http_code}')

    [ "$http_code" -eq 400 ]
}

@test "CREATE without start_date returns 400 Bad Request" {
    http_code=$(curl -s -X POST "$SERVICE_URL/subscriptions" \
        -o /dev/null \
        -H "Content-Type: application/json" \
        -d '{
                "service_name": "Yandex Plus",
                "price": 400,
                "user_id": "60601fee-2bf1-4721-ae6f-7636e79a0cba",
            }' \
        -w '%{http_code}')

    [ "$http_code" -eq 400 ]
}

@test "CREATE with incorrect start_date returns 400 Bad Request" {
    http_code=$(curl -s -X POST "$SERVICE_URL/subscriptions" \
        -o /dev/null \
        -H "Content-Type: application/json" \
        -d '{
                "service_name": "Yandex Plus",
                "price": 400,
                "user_id": "60601fee-2bf1-4721-ae6f-7636e79a0cba",
                "start_date": "02-07-2025"
            }' \
        -w '%{http_code}')

    [ "$http_code" -eq 400 ]
}

@test "CREATE with incorrect end_date returns 400 Bad Request" {
    http_code=$(curl -s -X POST "$SERVICE_URL/subscriptions" \
        -o /dev/null \
        -H "Content-Type: application/json" \
        -d '{
                "service_name": "Yandex Plus",
                "price": 400,
                "user_id": "60601fee-2bf1-4721-ae6f-7636e79a0cba",
                "start_date": "07-2025",
                "end_date": "02-10-2025"
            }' \
        -w '%{http_code}')

    [ "$http_code" -eq 400 ]
}

@test "CREATE with negative price returns 400 Bad Request" {
    http_code=$(curl -s -X POST "$SERVICE_URL/subscriptions" \
        -o /dev/null \
        -H "Content-Type: application/json" \
        -d '{
                "service_name": "Yandex Plus",
                "price": -400,
                "user_id": "60601fee-2bf1-4721-ae6f-7636e79a0cba",
                "start_date": "07-2025"
            }' \
        -w '%{http_code}')

    [ "$http_code" -eq 400 ]
}

@test "CREATE with correct payload creates entity which can be fetched via READ and returns 201 Created" {
    result=$(curl -s -X POST "$SERVICE_URL/subscriptions" \
        -H "Content-Type: application/json" \
        -d '{
                "service_name": "Yandex Plus",
                "price": 400,
                "user_id": "60601fee-2bf1-4721-ae6f-7636e79a0cba",
                "start_date": "07-2025"
            }' \
        -w '\n%{http_code}')
    http_code=$(echo "$result" | tail -n1)
    body=$(echo "$result" | head -n -1)

    [ "$http_code" -eq 201 ]

    run jq -e 'type == "object"' <<< "$body"
    [ "$status" -eq 0 ]
    run jq -e '.id' <<< "$body"
    [ "$status" -eq 0 ]

    id=$(jq '.id' <<< "$body")

    result=$(curl -s "$SERVICE_URL/subscriptions/$id" \
        -w '\n%{http_code}')
    http_code=$(echo "$result" | tail -n1)
    body=$(echo "$result" | head -n -1)

    [ "$http_code" -eq 200 ]

    run jq -e 'type == "object"' <<< "$body"
    [ "$status" -eq 0 ]

    echo "$id" > /tmp/yandex_sub_id
}

@test "READ with nonexisting id returns 404 Not Found" {
    http_code=$(curl -s "$SERVICE_URL/subscriptions/1337" \
        -o /dev/null \
        -w '%{http_code}')
    [ "$http_code" -eq 404 ]
}

@test "READ with incorrect id returns 400 Bad Request" {
    http_code=$(curl -s "$SERVICE_URL/subscriptions/foo" \
        -o /dev/null \
        -w '%{http_code}')
    [ "$http_code" -eq 400 ]
}

@test "UPDATE without service_name returns 400 Bad Request" {
    id=$(cat /tmp/yandex_sub_id)
    http_code=$(curl -s -X PUT "$SERVICE_URL/subscriptions/$id" \
        -o /dev/null \
        -H "Content-Type: application/json" \
        -d '{
                "price": 400,
                "user_id": "60601fee-2bf1-4721-ae6f-7636e79a0cba",
                "start_date": "07-2025"
            }' \
        -w '%{http_code}')

    [ "$http_code" -eq 400 ]
}

@test "UPDATE without price returns 400 Bad Request" {
    id=$(cat /tmp/yandex_sub_id)
    http_code=$(curl -s -X PUT "$SERVICE_URL/subscriptions/$id" \
        -o /dev/null \
        -H "Content-Type: application/json" \
        -d '{
                "service_name": "Yandex Plus",
                "user_id": "60601fee-2bf1-4721-ae6f-7636e79a0cba",
                "start_date": "07-2025"
            }' \
        -w '%{http_code}')

    [ "$http_code" -eq 400 ]
}

@test "UPDATE without user_id returns 400 Bad Request" {
    id=$(cat /tmp/yandex_sub_id)
    http_code=$(curl -s -X PUT "$SERVICE_URL/subscriptions/$id" \
        -o /dev/null \
        -H "Content-Type: application/json" \
        -d '{
                "service_name": "Yandex Plus",
                "price": 400,
                "start_date": "07-2025"
            }' \
        -w '%{http_code}')

    [ "$http_code" -eq 400 ]
}

@test "UPDATE with incorrect user_id returns 400 Bad Request" {
    id=$(cat /tmp/yandex_sub_id)
    http_code=$(curl -s -X PUT "$SERVICE_URL/subscriptions/$id" \
        -o /dev/null \
        -H "Content-Type: application/json" \
        -d '{
                "service_name": "Yandex Plus",
                "price": 400,
                "user_id": "60601fee-2bf1-4721-ae6f-7636e79a0cba1",
                "start_date": "07-2025"
            }' \
        -w '%{http_code}')

    [ "$http_code" -eq 400 ]
}

@test "UPDATE without start_date returns 400 Bad Request" {
    id=$(cat /tmp/yandex_sub_id)
    http_code=$(curl -s -X PUT "$SERVICE_URL/subscriptions/$id" \
        -o /dev/null \
        -H "Content-Type: application/json" \
        -d '{
                "service_name": "Yandex Plus",
                "price": 400,
                "user_id": "60601fee-2bf1-4721-ae6f-7636e79a0cba",
            }' \
        -w '%{http_code}')

    [ "$http_code" -eq 400 ]
}

@test "UPDATE with incorrect start_date returns 400 Bad Request" {
    id=$(cat /tmp/yandex_sub_id)
    http_code=$(curl -s -X PUT "$SERVICE_URL/subscriptions/$id" \
        -o /dev/null \
        -H "Content-Type: application/json" \
        -d '{
                "service_name": "Yandex Plus",
                "price": 400,
                "user_id": "60601fee-2bf1-4721-ae6f-7636e79a0cba",
                "start_date": "02-07-2025"
            }' \
        -w '%{http_code}')

    [ "$http_code" -eq 400 ]
}

@test "UPDATE with incorrect end_date returns 400 Bad Request" {
    id=$(cat /tmp/yandex_sub_id)
    http_code=$(curl -s -X PUT "$SERVICE_URL/subscriptions/$id" \
        -o /dev/null \
        -H "Content-Type: application/json" \
        -d '{
                "service_name": "Yandex Plus",
                "price": 400,
                "user_id": "60601fee-2bf1-4721-ae6f-7636e79a0cba",
                "start_date": "07-2025",
                "end_date": "02-10-2025"
            }' \
        -w '%{http_code}')

    [ "$http_code" -eq 400 ]
}

@test "UPDATE with negative price returns 400 Bad Request" {
    id=$(cat /tmp/yandex_sub_id)
    http_code=$(curl -s -X PUT "$SERVICE_URL/subscriptions/$id" \
        -o /dev/null \
        -H "Content-Type: application/json" \
        -d '{
                "service_name": "Yandex Plus",
                "price": -400,
                "user_id": "60601fee-2bf1-4721-ae6f-7636e79a0cba",
                "start_date": "07-2025"
            }' \
        -w '%{http_code}')

    [ "$http_code" -eq 400 ]
}

@test "UPDATE with nonexisting id returns 404 Not Found" {
    http_code=$(curl -s -X PUT "$SERVICE_URL/subscriptions/1337" \
        -o /dev/null \
        -H "Content-Type: application/json" \
        -d '{
                "service_name": "Yandex Plus",
                "price": 500,
                "user_id": "60601fee-2bf1-4721-ae6f-7636e79a0cba",
                "start_date": "07-2025"
            }' \
        -w '%{http_code}')
    [ "$http_code" -eq 404 ]
}

@test "UPDATE with incorrect id returns 400 Bad Request" {
    http_code=$(curl -s -X PUT "$SERVICE_URL/subscriptions/foo" \
        -o /dev/null \
        -H "Content-Type: application/json" \
        -d '{
                "service_name": "Yandex Plus",
                "price": 500,
                "user_id": "60601fee-2bf1-4721-ae6f-7636e79a0cba",
                "start_date": "07-2025"
            }' \
        -w '%{http_code}')
    [ "$http_code" -eq 400 ]
}

@test "Nothing changed after all these failed UPDATEs" {
    id=$(cat /tmp/yandex_sub_id)
    body=$(curl -s "$SERVICE_URL/subscriptions/$id")

    run jq -e '.service_name == "Yandex Plus"' <<< "$body"
    [ "$status" -eq 0 ]
    run jq -e '.price == 400' <<< "$body"
    [ "$status" -eq 0 ]
    run jq -e '.user_id == "60601fee-2bf1-4721-ae6f-7636e79a0cba"' <<< "$body"
    [ "$status" -eq 0 ]
    run jq -e '.start_date == "07-2025"' <<< "$body"
    [ "$status" -eq 0 ]
}

@test "UPDATE with correct payload updates entity and retuns 200 OK" {
    id=$(cat /tmp/yandex_sub_id)
    result=$(curl -s -X PUT "$SERVICE_URL/subscriptions/$id" \
        -H "Content-Type: application/json" \
        -d '{
                "service_name": "Yandex Plus",
                "price": 500,
                "user_id": "60601fee-2bf1-4721-ae6f-7636e79a0cba",
                "start_date": "07-2025"
            }' \
        -w '\n%{http_code}')
    http_code=$(echo "$result" | tail -n1)
    body=$(echo "$result" | head -n -1)

    [ "$http_code" -eq 200 ]

    run jq -e 'type == "object"' <<< "$body"
    [ "$status" -eq 0 ]
    run jq -e '.price == 500' <<< "$body"
    [ "$status" -eq 0 ]

    result=$(curl -s "$SERVICE_URL/subscriptions/$id" \
        -w '\n%{http_code}')
    http_code=$(echo "$result" | tail -n1)
    body=$(echo "$result" | head -n -1)

    [ "$http_code" -eq 200 ]

    run jq -e '.price == 500' <<< "$body"
    [ "$status" -eq 0 ]
}

@test "DELETE with nonexisting id returns 404 Not Found" {
    http_code=$(curl -s -X DELETE "$SERVICE_URL/subscriptions/1337" \
        -o /dev/null \
        -w '%{http_code}')
    [ "$http_code" -eq 404 ]
}

@test "DELETE with incorrect id returns 400 Bad Request" {
    http_code=$(curl -s -X DELETE "$SERVICE_URL/subscriptions/foo" \
        -o /dev/null \
        -w '%{http_code}')
    [ "$http_code" -eq 400 ]
}

@test "DELETE with correct id successfully deletes entity and returns 204 No Content" {
    id=$(cat /tmp/yandex_sub_id)
    http_code=$(curl -s -X DELETE "$SERVICE_URL/subscriptions/$id" \
        -o /dev/null \
        -w '%{http_code}')
    [ "$http_code" -eq 204 ]

    body=$(curl -s "$SERVICE_URL/subscriptions")
    run jq -e 'length == 0' <<< "$body"
    [ "$status" -eq 0 ]
}

@test "LIST returns array and status 200 OK" {
    result=$(curl -s "$SERVICE_URL/subscriptions" \
        -w '\n%{http_code}')
    http_code=$(echo "$result" | tail -n1)
    body=$(echo "$result" | head -n -1)

    [ "$http_code" -eq 200 ]
    
    run jq -e 'type == "array"' <<< "$body"
    [ "$status" -eq 0 ]
}

@test "/subscriptions_summary_cost returns 0 with empty table and status 200 OK" {
    result=$(curl -s "$SERVICE_URL/subscriptions_summary_cost?from=01-2000&to=05-2026" \
        -w '\n%{http_code}')
    http_code=$(echo "$result" | tail -n1)
    body=$(echo "$result" | head -n -1)

    [ "$http_code" -eq 200 ]
    
    run jq -e '.result == 0' <<< "$body"
    [ "$status" -eq 0 ]
}

@test "/subscriptions_summary_cost calculates correctly" {
    ids_file="$BATS_TEST_TMPDIR/ids.txt"
    : > $ids_file
    # create subs
    body=$(curl -s -X POST "$SERVICE_URL/subscriptions" \
        -H "Content-Type: application/json" \
        -d '{
                "service_name": "Sub 1",
                "price": 400,
                "user_id": "60601fee-2bf1-4721-ae6f-7636e79a0cba",
                "start_date": "07-2025"
            }')
    echo $(jq '.id' <<< "$body") >> $ids_file

    body=$(curl -s -X POST "$SERVICE_URL/subscriptions" \
        -H "Content-Type: application/json" \
        -d '{
                "service_name": "Sub 2",
                "price": 1000,
                "user_id": "60601fee-2bf1-4721-ae6f-7636e79a0cba",
                "start_date": "09-2025",
                "end_date": "01-2026"
            }')
    echo $(jq '.id' <<< "$body") >> $ids_file

    body=$(curl -s -X POST "$SERVICE_URL/subscriptions" \
        -H "Content-Type: application/json" \
        -d '{
                "service_name": "Sub 2",
                "price": 1000,
                "user_id": "60601fee-2bf1-4721-ae6f-7636e79a0cba",
                "start_date": "02-2026"
            }')
    echo $(jq '.id' <<< "$body") >> $ids_file

    body=$(curl -s -X POST "$SERVICE_URL/subscriptions" \
        -H "Content-Type: application/json" \
        -d '{
                "service_name": "Sub 1",
                "price": 400,
                "user_id": "9bf12469-11f4-d044-88be-67f189e736ff",
                "start_date": "09-2025",
                "end_date": "11-2025"
            }')
    echo $(jq '.id' <<< "$body") >> $ids_file

    body=$(curl -s -X POST "$SERVICE_URL/subscriptions" \
        -H "Content-Type: application/json" \
        -d '{
                "service_name": "Sub 2",
                "price": 1000,
                "user_id": "9bf12469-11f4-d044-88be-67f189e736ff",
                "start_date": "12-2025",
                "end_date": "02-2026"
            }')
    echo $(jq '.id' <<< "$body") >> $ids_file

    # checks
    body=$(curl -s "$SERVICE_URL/subscriptions_summary_cost?from=07-2025&to=09-2025")
    run jq -e '.result == 800' <<< "$body"
    [ "$status" -eq 0 ]

    body=$(curl -s "$SERVICE_URL/subscriptions_summary_cost?from=09-2025&to=12-2025")
    run jq -e '.result == 5000' <<< "$body"
    [ "$status" -eq 0 ]

    body=$(curl -s "$SERVICE_URL/subscriptions_summary_cost?from=09-2025&to=12-2025&user_id=60601fee-2bf1-4721-ae6f-7636e79a0cba")
    run jq -e '.result == 4200' <<< "$body"
    [ "$status" -eq 0 ]

    body=$(curl -s "$SERVICE_URL/subscriptions_summary_cost?from=11-2025&to=01-2026&service_name=Sub%202")
    run jq -e '.result == 3000' <<< "$body"
    [ "$status" -eq 0 ]

    body=$(curl -s "$SERVICE_URL/subscriptions_summary_cost?from=08-2025&to=05-2026&user_id=60601fee-2bf1-4721-ae6f-7636e79a0cba&service_name=Sub%202")
    run jq -e '.result == 7000' <<< "$body"
    [ "$status" -eq 0 ]
}

teardown() {
    if [ -f "$BATS_TEST_TMPDIR/ids.txt" ]; then
        while read -r id; do
            curl -s -X DELETE "$SERVICE_URL/subscriptions/$id" || true
        done < "$BATS_TEST_TMPDIR/ids.txt"
        rm -f "$BATS_TEST_TMPDIR/ids.txt"
    fi
}
