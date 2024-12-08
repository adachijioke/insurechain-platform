# insurechain-platform

## Overview

This smart contract provides a decentralized solution for managing healthcare claims on the Stacks blockchain. It ensures transparency and accountability in healthcare billing, enabling seamless interactions between patients, providers, and administrators.

## Key Features

### 1. Provider Registration
- Register verified healthcare providers.
- Store provider details:
  - Name
  - License number

### 2. Claim Submission
- Submit claims for healthcare services.
- Each claim includes:
  - Patient details
  - Service date and description
  - Cost and initial status ("Submitted")

### 3. Claim Tracking
- Patients can view all claims associated with their account.
- Administrators can manage and update claim statuses.

### 4. Claim Status Management
- Update claim statuses (e.g., "Submitted," "Approved," "Rejected").
- Only authorized administrators can perform status updates.

## Security Features

- **Role-based Authorization:** Only registered providers can submit claims, and only the contract owner can register providers or update claim statuses.
- **Error Handling:** Comprehensive error constants for unauthorized actions, duplicates, and missing data.
- **Data Validation:** Enforces correct formats for input fields like descriptions, costs, and statuses.

## Smart Contract Functions

### `register-provider`
- Registers a healthcare provider.
- Requires provider name and license number.
- Restricted to the contract owner.

### `submit-claim`
- Submits a healthcare claim.
- Requires details like patient, service description, cost, and service date.
- Accessible to registered providers only.

### `get-claim`
- Retrieves details of a specific claim by ID.
- Available to all users.

### `get-patient-claims`
- Fetches all claims associated with a specific patient.
- Helps patients track their claims.

### `update-claim-status`
- Updates the status of a claim (e.g., "Approved," "Rejected").
- Restricted to the contract owner.

### `get-provider-details`
- Retrieves details of a registered provider.
- Useful for verifying provider credentials.

## Error Handling

The contract employs detailed error codes for better clarity:
- `ERR-UNAUTHORIZED` (`u401`): Action not permitted for the user.
- `ERR-NOT-FOUND` (`u404`): Data or entity does not exist.
- `ERR-ALREADY-EXISTS` (`u409`): Duplicate entries are not allowed.

## Usage Limitations

- Maximum of 50 claims per patient.
- Providers must be registered to interact with the contract.
- Only the contract owner can register providers or modify claim statuses.

## Best Practices

1. Verify provider registration before submitting claims.
2. Use unique service descriptions for accurate claim tracking.
3. Regularly update claim statuses for better patient visibility.
4. Maintain compliance with healthcare regulations when submitting claims.
5. Audit claims periodically for accuracy and completeness.

## Example Workflow

```clarity
;; Register a provider
(register-provider "Healthcare Provider" "License123")

;; Submit a claim
(submit-claim patient-principal u1686123456 "Routine Checkup" u100)

;; Retrieve patient claims
(get-patient-claims patient-principal)

;; Update claim status
(update-claim-status u1 "Approved")
```

## Potential Use Cases

- Hospitals submitting insurance claims.
- Patients tracking their healthcare expenses.
- Administrators managing claim approval workflows.
- Providers verifying their registration status.

---

Does this align with what you had in mind? 😊