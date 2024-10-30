;; Budget Management Smart Contract
;; Allows users to set budgets, track expenses, income, and manage their financial goals

;; Data Maps
(define-map budgets
    {user: principal}  ;; Unique identifier for each user
    {
        total-budget: uint,
        remaining-budget: uint,
        total-income: uint
    }
)

(define-map expenses
    {
        user: principal,
        expense-id: uint
    }  
    {
        amount: uint,
        category: (string-ascii 9),
        timestamp: uint
    }
)

(define-map income-entries
    {
        user: principal,
        income-id: uint
    }
    {
        amount: uint,
        source: (string-ascii 9),
        timestamp: uint
    }
)

;; Data Variables
(define-data-var expense-counter uint u0) ;; Counter for expense ID
(define-data-var income-counter uint u0)  ;; Counter for income ID

;; Error Constants
(define-constant ERR-INVALID-BUDGET (err u100))
(define-constant ERR-BUDGET-NOT-SET (err u101))
(define-constant ERR-INVALID-AMOUNT (err u102))
(define-constant ERR-INSUFFICIENT-BUDGET (err u103))
(define-constant ERR-NO-BUDGET-FOUND (err u104))
(define-constant ERR-EXPENSE-NOT-FOUND (err u105))
(define-constant ERR-INCOME-NOT-FOUND (err u106))
(define-constant ERR-INVALID-CATEGORY (err u107))
(define-constant ERR-INVALID-SOURCE (err u108))

;; Valid categories and sources lists
(define-constant VALID-CATEGORIES (list 
    "food"
    "housing"
    "transport"
    "utilities"
    "health"
    "leisure"
    "other"
))

(define-constant VALID-INCOME-SOURCES (list
    "salary"
    "business"
    "invest"
    "freelance"
    "other"
))

;; Helper Functions
(define-private (is-valid-string (input (string-ascii 10)))
    (and
        (not (is-eq input ""))
        (<= (len input) u10)
    )
)

(define-private (is-valid-category (category (string-ascii 9)))
    (and
        (is-valid-string category)
        (is-some (index-of VALID-CATEGORIES category))
    )
)

(define-private (is-valid-source (source (string-ascii 9)))
    (and
        (is-valid-string source)
        (is-some (index-of VALID-INCOME-SOURCES source))
    )
)

;; Public Functions
;; Function to set or update a budget for a user
(define-public (set-budget (total-budget uint))
    (begin
        (asserts! (> total-budget u0) ERR-INVALID-BUDGET)
        (let ((current-budget (map-get? budgets {user: tx-sender})))
            (map-set budgets
                {user: tx-sender}
                {
                    total-budget: total-budget,
                    remaining-budget: total-budget,
                    total-income: (match current-budget
                        budget (get total-income budget)
                        u0)
                }
            )
            (ok total-budget)
        )
    )
)

;; Function to add an expense
(define-public (add-expense (amount uint) (category (string-ascii 9)))
    (let ((expense-id (var-get expense-counter)))
        (begin
            (asserts! (is-some (map-get? budgets {user: tx-sender})) ERR-BUDGET-NOT-SET)
            (asserts! (> amount u0) ERR-INVALID-AMOUNT)
            (asserts! (is-valid-category category) ERR-INVALID-CATEGORY)

            (let ((current-budget (unwrap-panic (map-get? budgets {user: tx-sender}))))
                (asserts! (>= (get remaining-budget current-budget) amount) ERR-INSUFFICIENT-BUDGET)

                ;; Update remaining budget
                (map-set budgets
                    {user: tx-sender}
                    {
                        total-budget: (get total-budget current-budget),
                        remaining-budget: (- (get remaining-budget current-budget) amount),
                        total-income: (get total-income current-budget)
                    }
                )

                ;; Store the expense
                (map-set expenses
                    {
                        user: tx-sender,
                        expense-id: expense-id
                    }
                    {
                        amount: amount,
                        category: category,
                        timestamp: block-height
                    }
                )

                ;; Increment counter
                (var-set expense-counter (+ expense-id u1))
                (ok expense-id)
            )
        )
    )
)

;; Function to add income
(define-public (add-income (amount uint) (source (string-ascii 9)))
    (let ((income-id (var-get income-counter)))
        (begin
            (asserts! (> amount u0) ERR-INVALID-AMOUNT)
            (asserts! (is-valid-source source) ERR-INVALID-SOURCE)

            ;; Initialize budget if not exists
            (match (map-get? budgets {user: tx-sender})
                current-budget 
                (map-set budgets
                    {user: tx-sender}
                    {
                        total-budget: (get total-budget current-budget),
                        remaining-budget: (get remaining-budget current-budget),
                        total-income: (+ (get total-income current-budget) amount)
                    }
                )
                (map-set budgets
                    {user: tx-sender}
                    {
                        total-budget: u0,
                        remaining-budget: u0,
                        total-income: amount
                    }
                )
            )

            ;; Store the income entry
            (map-set income-entries
                {
                    user: tx-sender,
                    income-id: income-id
                }
                {
                    amount: amount,
                    source: source,
                    timestamp: block-height
                }
            )

            ;; Increment counter
            (var-set income-counter (+ income-id u1))
            (ok income-id)
        )
    )
)

;; Read-only Functions
;; Function to get the remaining budget for the user
(define-read-only (get-remaining-budget (user principal))
    (match (map-get? budgets {user: user})
        budget (ok (get remaining-budget budget))
        ERR-NO-BUDGET-FOUND
    )
)

;; Function to get total income for the user
(define-read-only (get-total-income (user principal))
    (match (map-get? budgets {user: user})
        budget (ok (get total-income budget))
        ERR-NO-BUDGET-FOUND
    )
)

;; Function to retrieve details of an expense by ID
(define-read-only (get-expense (expense-id uint))
    (match (map-get? expenses {user: tx-sender, expense-id: expense-id})
        expense (ok expense)
        ERR-EXPENSE-NOT-FOUND
    )
)

;; Function to retrieve details of an income entry by ID
(define-read-only (get-income (income-id uint))
    (match (map-get? income-entries {user: tx-sender, income-id: income-id})
        income (ok income)
        ERR-INCOME-NOT-FOUND
    )
)

;; Function to get valid categories
(define-read-only (get-valid-categories)
    (ok VALID-CATEGORIES)
)

;; Function to get valid income sources
(define-read-only (get-valid-income-sources)
    (ok VALID-INCOME-SOURCES)
)

;; Function to reset the budget and all expenses for a user
(define-public (reset-budget)
    (begin
        (map-delete budgets {user: tx-sender})
        (ok "Budget reset successful")
    )
)
