/**
 * Application error with HTTP status code
 */
export class AppError extends Error {
  constructor(
    public message: string,
    public statusCode: number = 500,
    public isOperational: boolean = true
  ) {
    super(message);
    Object.setPrototypeOf(this, new.target.prototype);
  }
}

export class ValidationError extends AppError {
  constructor(message: string) {
    super(message, 400);
  }
}

export class NotFoundError extends AppError {
  constructor(resource: string, id?: string) {
    super(`${resource} ${id ? `with id ${id} ` : ""}not found`, 404);
  }
}

export class AuthenticationError extends AppError {
  constructor(message: string = "Authentication failed") {
    super(message, 401);
  }
}

export class AuthorizationError extends AppError {
  constructor(message: string = "Access denied") {
    super(message, 403);
  }
}

export class ConflictError extends AppError {
  constructor(message: string) {
    super(message, 409);
  }
}
