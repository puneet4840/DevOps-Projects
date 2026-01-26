variable "enable-app-service" {
  type = bool
  default = false
  description = "This variable will be used in if-else block whether to create app-service or not."
}

variable "enable-front-door" {
  type = bool
  default = false
  description = "This variable will be used in if-else block whether to create front door or not."
}

variable "enable-sql" {
  type = bool
  default = false
  description = "This variable will be used in if-else block whether to create sql server or not."
}

