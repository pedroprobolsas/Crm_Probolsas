import React from 'react';
import { BrowserRouter as Router, Routes, Route, Navigate } from 'react-router-dom';
import { QueryClient, QueryClientProvider } from '@tanstack/react-query';
import { Sidebar } from './components/Sidebar';
import { AuthGuard } from './components/AuthGuard';
import { Login } from './pages/Login';
import { ResetPassword } from './pages/ResetPassword';
import { Dashboard } from './pages/Dashboard';
import { Clients } from './pages/Clients';
import { Products } from './pages/Products';
import { Communications } from './pages/Communications';
import { Reports } from './pages/Reports';
import { AgentManagement } from './pages/AgentManagement';
import { ProductConfig } from './pages/ProductConfig';
import { Toaster } from 'sonner';

const queryClient = new QueryClient({
  defaultOptions: {
    queries: {
      staleTime: 1000 * 60 * 5, // 5 minutes
      refetchOnWindowFocus: false,
    },
  },
});

function App() {
  return (
    <QueryClientProvider client={queryClient}>
      <Router>
        <Toaster position="top-right" richColors closeButton />
        <Routes>
          <Route path="/login" element={<Login />} />
          <Route path="/reset-password" element={<ResetPassword />} />
          
          {/* Rutas protegidas básicas */}
          <Route path="/" element={
            <AuthGuard>
              <MainLayout>
                <Dashboard />
              </MainLayout>
            </AuthGuard>
          } />
          <Route path="/clients" element={
            <AuthGuard>
              <MainLayout>
                <Clients />
              </MainLayout>
            </AuthGuard>
          } />
          <Route path="/communications" element={
            <AuthGuard>
              <MainLayout>
                <Communications />
              </MainLayout>
            </AuthGuard>
          } />
          <Route path="/reports" element={
            <AuthGuard>
              <MainLayout>
                <Reports />
              </MainLayout>
            </AuthGuard>
          } />

          {/* Rutas protegidas solo para administradores */}
          <Route path="/products" element={
            <AuthGuard requireAdmin>
              <MainLayout>
                <Products />
              </MainLayout>
            </AuthGuard>
          } />
          <Route path="/agent-management" element={
            <AuthGuard requireAdmin>
              <MainLayout>
                <AgentManagement />
              </MainLayout>
            </AuthGuard>
          } />
          <Route path="/config/products" element={
            <AuthGuard requireAdmin>
              <MainLayout>
                <ProductConfig />
              </MainLayout>
            </AuthGuard>
          } />

          <Route path="*" element={<Navigate to="/" replace />} />
        </Routes>
      </Router>
    </QueryClientProvider>
  );
}

function MainLayout({ children }: { children: React.ReactNode }) {
  return (
    <div className="flex h-screen bg-gray-100">
      <Sidebar onClose={() => {}} />
      <main className="flex-1 overflow-auto">
        {children}
      </main>
    </div>
  );
}

export default App;