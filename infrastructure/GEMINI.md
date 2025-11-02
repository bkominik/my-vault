# Gemini Guidelines for this Project

This document provides guidelines for Large Language Models (LLMs) like Gemini when working on this codebase. Please adhere to these principles to ensure the quality, security, and maintainability of the project.

## Core Principles

1.  **Security First**: Always prioritize security in all changes. This includes but is not limited to:
    *   Adhering to the principle of least privilege.
    *   Never hardcoding secrets or sensitive information.
    *   Using encrypted communication and storage where appropriate.
    *   Staying up-to-date with the latest security vulnerabilities and best practices for OpenTofu and GCP.

2.  **OpenTofu Best Practices**: Follow established best practices for writing OpenTofu code:
    *   Use a consistent and modular code structure.
    *   Keep modules focused on a single purpose.
    *   Use variables for parameterization and outputs for exposing resource attributes.
    *   Format code using `tofu fmt`.
    *   Use a remote backend for state management.

3.  **Simplicity and Maintainability**: Write code that is easy to understand and maintain.
    *   Prefer simple, clear, and declarative code over complex logic.
    *   Add comments only when the code's purpose is not immediately obvious.
    *   Refactor complex configurations into smaller, reusable modules.

## Workflow

1.  **Understand the Goal**: Before making any changes, take the time to understand the user's request and the existing codebase.
2.  **Plan Your Changes**: Create a to-do list or a plan of action before you start modifying files. This helps to ensure that you have a clear path to achieving the goal and that you have considered potential side effects.
3.  **Implement and Verify**: Implement the changes according to your plan. After making changes, verify them to ensure they work as expected and do not introduce any new issues.

## Debugging and Verification

1.  **Analyze Dependencies Holistically**: When debugging a resource, do not treat it in isolation. Always examine the configuration of its direct dependencies (e.g., for a VM, inspect the VPC, subnet, and base image). Errors often originate in the dependencies.

2.  **Validate Configuration Schema**: Do not guess syntax or keys for configuration files (e.g., `cloud-init.yaml`). Always refer to official documentation. When an error is persistent, use a built-in validation tool if available (e.g., `cloud-init schema --system` on a test instance) before reapplying the configuration.

3.  **Verify Asynchronous Operations Correctly**: For tasks that run in the background (like a `cloud-init` script), do not assume completion after a fixed time. First, use a status command (e.g., `cloud-init status`) to confirm the process is `done`. Only then, verify the results (e.g., checking if a package is installed).
