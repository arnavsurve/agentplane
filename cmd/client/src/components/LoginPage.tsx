import React, { useState, useEffect } from "react";
import { Button } from "./ui/button";
import { Input } from "./ui/input";
import { Label } from "./ui/label";
import {
  Card,
  CardContent,
  CardDescription,
  CardHeader,
  CardTitle,
} from "./ui/card";
import { Alert, AlertDescription } from "./ui/alert";
import { Loader2, User } from "lucide-react";
import { Link, useNavigate, useLocation } from "react-router-dom";
import { useAuth } from "../auth/AuthContext";
import type { LoginCredentials } from "../types/auth.types";
import { OAuthButtons, OAuthDivider } from "./OAuthButtons";

export function LoginPage() {
  const [formData, setFormData] = useState<LoginCredentials>({
    email: "",
    password: "",
  });
  const [oauthError, setOauthError] = useState<string | null>(null);
  const { login, isLoading, error, clearError } = useAuth();
  const navigate = useNavigate();
  const location = useLocation();

  // Check for OAuth error in query params
  useEffect(() => {
    const params = new URLSearchParams(location.search);
    const errorParam = params.get('error');
    const errorDesc = params.get('description');
    
    if (errorParam) {
      const errorMessages: Record<string, string> = {
        'access_denied': 'Authorization was denied. Please try again.',
        'invalid_state': 'Security validation failed. Please try again.',
        'github_api_error': 'Unable to connect to GitHub. Please try again later.',
        'google_api_error': 'Unable to connect to Google. Please try again later.',
        'no_email': 'No email address found. Please ensure your account has a verified email.',
        'email_already_exists': 'An account with this email already exists. Please log in with your password.',
        'user_creation_failed': 'Failed to create account. Please try again.',
        'token_generation_failed': 'Authentication failed. Please try again.',
        'token_exchange_failed': 'Authentication failed. Please try again.'
      };
      
      setOauthError(errorMessages[errorParam] || errorDesc || 'Authentication failed. Please try again.');
      
      // Clean up URL
      const newUrl = window.location.pathname;
      window.history.replaceState({}, document.title, newUrl);
    }
  }, [location]);

  // Clear any previous errors when user starts typing
  useEffect(() => {
    if (error) {
      clearError();
    }
    if (oauthError) {
      setOauthError(null);
    }
  }, [formData.email, formData.password, error, clearError, oauthError]);

  const handleInputChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    const { name, value } = e.target;
    setFormData((prev) => ({
      ...prev,
      [name]: value,
    }));
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();

    try {
      await login(formData);
      
      // Get the intended destination or default to dashboard
      const from = location.state?.from?.pathname || "/dashboard";
      navigate(from, { replace: true });
    } catch (err) {
      // Error is handled by the auth context
      console.error("Login failed:", err);
    }
  };

  return (
    <div className="min-h-screen flex items-center justify-center bg-background p-4">
      <div className="w-full max-w-md">
        <Card>
          <CardHeader className="space-y-1 text-center">
            <div className="mx-auto w-12 h-12 bg-primary rounded-full flex items-center justify-center mb-4">
              <User className="w-6 h-6 text-primary-foreground" />
            </div>
            <CardTitle className="text-2xl">Welcome back</CardTitle>
            <CardDescription>
              Enter your email below to sign in to your account
            </CardDescription>
          </CardHeader>
          <CardContent className="space-y-4">
            {/* OAuth Buttons */}
            <OAuthButtons mode="login" />
            
            {/* Divider */}
            <OAuthDivider />
            
            <form onSubmit={handleSubmit} className="space-y-4">
              <div className="space-y-2">
                <Label htmlFor="email">Email</Label>
                <Input
                  id="email"
                  name="email"
                  type="email"
                  placeholder="m@example.com"
                  value={formData.email}
                  onChange={handleInputChange}
                  required
                />
              </div>
              <div className="space-y-2">
                <Label htmlFor="password">Password</Label>
                <Input
                  id="password"
                  name="password"
                  type="password"
                  placeholder="Enter your password"
                  value={formData.password}
                  onChange={handleInputChange}
                  required
                />
              </div>

              {(error || oauthError) && (
                <Alert variant="destructive">
                  <AlertDescription>{error || oauthError}</AlertDescription>
                </Alert>
              )}

              <Button type="submit" disabled={isLoading} className="w-full">
                {isLoading && <Loader2 className="mr-2 h-4 w-4 animate-spin" />}
                Sign In
              </Button>
            </form>

            <div className="text-center space-y-2">
              <Button variant="link" className="text-sm">
                Forgot your password?
              </Button>
              <p className="text-sm text-muted-foreground">
                Don't have an account?{" "}
                <Link to="/signup" className="text-primary hover:underline cursor-pointer">
                  Sign up
                </Link>
              </p>
            </div>
          </CardContent>
        </Card>
      </div>
    </div>
  );
}

