import { BrowserRouter as Router, Routes, Route, Navigate } from 'react-router-dom'
import { Suspense, lazy } from 'react'
import { ThemeProvider } from './components/theme-provider'
import { AuthProvider } from './auth/AuthContext'
import { ProtectedRoute, PublicRoute } from './auth/ProtectedRoute'
import { Toaster } from './components/ui/sonner'

// Lazy load components
const LoginPage = lazy(() => import('./components/LoginPage').then(module => ({ default: module.LoginPage })))
const SignupPage = lazy(() => import('./components/SignupPage').then(module => ({ default: module.SignupPage })))
const Layout = lazy(() => import('./components/Layout').then(module => ({ default: module.Layout })))
const DashboardPage = lazy(() => import('./components/DashboardPage').then(module => ({ default: module.DashboardPage })))
const AgentsPage = lazy(() => import('./components/AgentsPage').then(module => ({ default: module.AgentsPage })))
const CreateAgentForm = lazy(() => import('./components/CreateAgentForm').then(module => ({ default: module.CreateAgentForm })))
const AgentDetailView = lazy(() => import('./components/AgentDetailView').then(module => ({ default: module.AgentDetailView })))
const ChatPage = lazy(() => import('./components/ChatPage').then(module => ({ default: module.ChatPage })))
const SettingsPage = lazy(() => import('./components/SettingsPage').then(module => ({ default: module.SettingsPage })))


function App() {
  return (
    <ThemeProvider defaultTheme="dark" storageKey="vite-ui-theme">
      <AuthProvider>
        <Router>
          <Suspense fallback={
            <div className="flex items-center justify-center h-screen">
              <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-primary"></div>
            </div>
          }>
            <Routes>
              {/* Public routes - redirect to dashboard if authenticated */}
              <Route 
                path="/signup" 
                element={
                  <PublicRoute>
                    <SignupPage />
                  </PublicRoute>
                } 
              />
              <Route 
                path="/login" 
                element={
                  <PublicRoute>
                    <LoginPage />
                  </PublicRoute>
                } 
              />
              
              {/* Protected routes with layout */}
              <Route 
                path="/" 
                element={
                  <ProtectedRoute>
                    <Layout />
                  </ProtectedRoute>
                }
              >
                <Route index element={<Navigate to="/dashboard" replace />} />
                <Route path="dashboard" element={<DashboardPage />} />
                <Route path="agents" element={<AgentsPage />} />
                <Route path="agents/create" element={<CreateAgentForm />} />
                <Route path="agents/:id" element={<AgentDetailView />} />
                <Route path="chat" element={<ChatPage />} />
                <Route path="settings" element={<SettingsPage />} />
              </Route>
              
              {/* Catch all route */}
              <Route 
                path="*" 
                element={<Navigate to="/dashboard" replace />}
              />
            </Routes>
          </Suspense>
        </Router>
        <Toaster 
          position="top-right"
          expand={true}
          richColors={true}
          closeButton={true}
        />
      </AuthProvider>
    </ThemeProvider>
  )
}

export default App
