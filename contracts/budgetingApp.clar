;; Budget Management Smart Contract
;; Allows users to set budgets, track expenses, and manage their financial goals

;; Data Maps
(define-map budgets
    {user: principal}  ;; Unique identifier for each user
    {
        total-budget: uint,
        remaining-budget: uint
    }
)

(define-map expenses
    {
        user: principal,
        expense-id: uint
    }  
    {
        amount: uint,
        category: (string-ascii 32),
        timestamp: uint
    }
)

;; Data Variables
(define-data-var expense-counter uint u0) ;; Counter for expense ID

;; Error Constants
(define-constant ERR-INVALID-BUDGET (err u100))
(define-constant ERR-BUDGET-NOT-SET (err u101))
(define-constant ERR-INVALID-AMOUNT (err u102))
(define-constant ERR-INSUFFICIENT-BUDGET (err u103))
(define-constant ERR-NO-BUDGET-FOUND (err u104))
(define-constant ERR-EXPENSE-NOT-FOUND (err u105))

;; Public Functions

;; Function to set or update a budget for a user
(define-public (set-budget (total-budget uint))
    (begin
        (asserts! (> total-budget u0) ERR-INVALID-BUDGET)
        (map-set budgets
            {user: tx-sender}
            {
                total-budget: total-budget,
                remaining-budget: total-budget
            }
        )
        (ok total-budget)
    )
)

;; Function to add an expense
(define-public (add-expense (amount uint) (category (string-ascii 32)))
    (let ((expense-id (var-get expense-counter)))
        (begin
            (asserts! (is-some (map-get? budgets {user: tx-sender})) ERR-BUDGET-NOT-SET)
            (asserts! (> amount u0) ERR-INVALID-AMOUNT)

            (let ((current-budget (unwrap-panic (map-get? budgets {user: tx-sender}))))
                (asserts! (>= (get remaining-budget current-budget) amount) ERR-INSUFFICIENT-BUDGET)

                ;; Update remaining budget
                (map-set budgets
                    {user: tx-sender}
                    {
                        total-budget: (get total-budget current-budget),
                        remaining-budget: (- (get remaining-budget current-budget) amount)
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

;; Read-only Functions

;; Function to get the remaining budget for the user
(define-read-only (get-remaining-budget (user principal))
    (match (map-get? budgets {user: user})
        budget (ok (get remaining-budget budget))
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

;; Function to reset the budget and all expenses for a user
(define-public (reset-budget)
    (begin
        (map-delete budgets {user: tx-sender})
        (ok "Budget reset successful")
    )
)

