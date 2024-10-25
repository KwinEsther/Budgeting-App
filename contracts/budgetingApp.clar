// Budgeting App Smart Contract in Clarity 2.0
// This contract enables users to set budgets, log expenses, and track remaining budget.

(define-map budgets
    ((user principal))  ;; Unique identifier for each user
    ((total-budget uint) (remaining-budget uint)))

(define-map expenses
    ((user principal) (expense-id uint))  ;; Unique ID per user and expense
    ((amount uint) (category (string-ascii 32)) (timestamp uint)))

(define-data-var expense-counter uint 0) ;; Counter for expense ID

;; Function to set or update a budget for a user
(define-public (set-budget (total-budget uint))
    (begin
        (asserts! (> total-budget u0) (err "Budget must be greater than zero"))
        (map-set budgets
            ((user tx-sender))
            ((total-budget total-budget)
             (remaining-budget total-budget)))
        (ok total-budget)
    )
)

;; Function to add an expense
(define-public (add-expense (amount uint) (category (string-ascii 32)))
    (let ((expense-id (var-get expense-counter)))
        (begin
            (asserts! (map-get? budgets ((user tx-sender))) (err "Set a budget first"))
            (asserts! (> amount u0) (err "Amount must be greater than zero"))

            ;; Get the user's current remaining budget
            (let ((current-budget (unwrap-panic (map-get budgets ((user tx-sender))))))
                (asserts! (>= (get remaining-budget current-budget) amount) (err "Insufficient budget"))

                ;; Update remaining budget
                (map-set budgets
                    ((user tx-sender))
                    ((total-budget (get total-budget current-budget))
                     (remaining-budget (- (get remaining-budget current-budget) amount))))

                ;; Store the expense in the expenses map
                (map-set expenses
                    ((user tx-sender) (expense-id expense-id))
                    ((amount amount)
                     (category category)
                     (timestamp (block-height))))

                ;; Increment the expense counter
                (var-set expense-counter (+ expense-id u1))

                (ok expense-id)
            )
        )
    )
)

;; Function to get the remaining budget for the user
(define-read-only (get-remaining-budget (user principal))
    (match (map-get budgets ((user user)))
        some-budget (ok (get remaining-budget some-budget))
        none (err "No budget found for this user")
    )
)

;; Function to retrieve details of an expense by ID
(define-read-only (get-expense (expense-id uint))
    (match (map-get expenses ((user tx-sender) (expense-id expense-id)))
        some-expense (ok some-expense)
        none (err "Expense not found")
    )
)

;; Function to reset the budget and all expenses for a user
(define-public (reset-budget)
    (begin
        (map-delete budgets ((user tx-sender)))
        (ok "Budget reset successful")
    )
)
