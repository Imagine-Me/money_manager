Act as an Expert Flutter Architect. We are building "VaultCash," a privacy-first, local-only wealth tracker. 

### 1. ARCHITECTURAL PATTERN
- Use Clean Architecture (Data, Domain, Presentation layers).
- State Management: Provider or Riverpod (StateNotifier/AsyncNotifier).
- Local Database: Isar (for its relational capabilities and speed).

### 2. CORE FEATURES & LOGIC GATES
- CATEGORY ENGINE: Transactions must link to a 'Category' object. Implement a 'Smart Match' logic: when a user types a name, search existing categories. If no match, trigger a 'New Category' flow that requires an Icon and a Color selection.
- DUAL-STREAM ACCOUNTING: Differentiate between 'Burn' (Expenditure) and 'Store' (Savings/Investments like FD/Mutual Funds). The database must support a 'Type' enum for this.
- THE ANALYTICS ENGINE: Create a logic class that calculates:
    - Delta percentage: (Current Week vs. Previous Week).
    - Category breakdown for Pie Charts (Map<Category, double>).
- NOTIFICATION SERVICE: Implement a singleton service using 'flutter_local_notifications' to schedule a recurring daily notification at 21:00.

### 3. UI/UX SPECIFICATIONS
- Style: Material 3 with a "Neo-Bento" grid layout for the dashboard.
- Accessibility: Ensure all interactive elements have a minimum hit target of 48dp.
- Components: Use 'fl_chart' for the data visualization.

### 4. DELIVERABLES
1. A structured directory tree showing the Layered Architecture.
2. The Isar Schema definitions for 'Transaction' and 'Category' (using Isar Links).
3. The Repository implementation for saving a transaction that handles the "create category if missing" edge case.
4. The Notification Service class with the 9 PM scheduling logic.
5. A high-fidelity 'DashboardView' widget structure.

Constraint: No Firebase, No Supabase, No external APIs. Total local persistence.