# Budgeting App Smart Contract

This Clarity 2.0 smart contract allows users to set and manage personal budgets on the Stacks blockchain. Users can allocate a budget, log expenses, track remaining budget, and reset their budget when needed. It is a foundational contract to build a decentralized budgeting app on the Stacks blockchain.

## Features
- **Set or Update Budget**: Allows a user to set an initial budget or update an existing one.
- **Add Expense**: Logs an expense with amount, category, and timestamp, deducting from the remaining budget.
- **View Remaining Budget**: Allows users to view the current remaining balance of their budget.
- **Retrieve Expense Details**: Fetches details of a specific expense based on an expense ID.
- **Reset Budget**: Deletes the budget and all expense data for a user, allowing them to start over.

## Contract Functions

### `set-budget (total-budget uint) -> Response<uint, int>`
Sets or updates a budget for the user. The initial `remaining-budget` is set equal to the `total-budget`.
- **Parameters**:
  - `total-budget`: Positive integer representing the user’s total budget.
- **Returns**:
  - On success: The `total-budget` value.
  - On failure: Error if budget is not a positive number.

### `add-expense (amount uint, category (string-ascii 32)) -> Response<uint, int>`
Logs an expense in the user's budget, deducting it from `remaining-budget`.
- **Parameters**:
  - `amount`: Positive integer representing the expense amount.
  - `category`: A string up to 32 ASCII characters that describes the category of the expense.
- **Returns**:
  - On success: The unique `expense-id` for the new expense.
  - On failure: Error if budget has not been set, amount is zero, or the remaining budget is insufficient.

### `get-remaining-budget (user principal) -> Response<uint, int>`
Fetches the remaining budget for a specific user.
- **Parameters**:
  - `user`: Principal representing the user for whom the remaining budget is being retrieved.
- **Returns**:
  - On success: Remaining budget as an unsigned integer.
  - On failure: Error if no budget is found.

### `get-expense (expense-id uint) -> Response<{amount uint, category (string-ascii 32), timestamp uint}, int>`
Fetches details of a specific expense by its `expense-id`.
- **Parameters**:
  - `expense-id`: The unique ID of the expense to retrieve.
- **Returns**:
  - On success: An object with `amount`, `category`, and `timestamp` of the expense.
  - On failure: Error if the expense does not exist.

### `reset-budget () -> Response<string, none>`
Deletes the user’s budget and all associated expenses.
- **Parameters**: None
- **Returns**:
  - On success: Confirmation message.
  - No failure cases defined.

## Data Structures
- **Map: `budgets`** - Stores each user's budget information.
  - Keys: `user` (principal)
  - Values: `total-budget` (uint), `remaining-budget` (uint)

- **Map: `expenses`** - Stores each expense with a unique ID.
  - Keys: `user` (principal), `expense-id` (uint)
  - Values: `amount` (uint), `category` (string-ascii 32), `timestamp` (uint)

- **Data Variable: `expense-counter`** - Keeps a count of expenses for unique ID generation.

## Example Usage
1. **Set a Budget**: 
   ```clarity
   (contract-call? .budgeting-contract set-budget u1000)
