import React from 'react';
import { NavLink } from 'react-router-dom';
import { 
  LayoutDashboard, 
  Users, 
  Package, 
  MessageSquare, 
  BarChart3,
  UserCog,
  LogOut,
  Settings
} from 'lucide-react';
import { useAuthStore } from '../lib/store/authStore';

const getNavItems = (isAdmin: boolean) => {
  const baseItems = [
    { to: '/', icon: LayoutDashboard, label: 'Panel Principal' },
    { to: '/clients', icon: Users, label: 'Clientes' },
    { to: '/communications', icon: MessageSquare, label: 'Comunicaciones' },
    { to: '/reports', icon: BarChart3, label: 'Reportes' },
  ];

  const adminItems = [
    { to: '/products', icon: Package, label: 'Productos' },
    { to: '/agent-management', icon: UserCog, label: 'Gestión de Asesores' },
    { to: '/config/products', icon: Settings, label: 'Configuración' },
  ];

  return isAdmin ? [...baseItems, ...adminItems] : baseItems;
};

export function Sidebar({ onClose }: { onClose: () => void }) {
  const { signOut, isAdmin, profile } = useAuthStore();
  const navItems = getNavItems(isAdmin());

  const handleLogout = async () => {
    try {
      await signOut();
    } catch (error) {
      console.error('Error al cerrar sesión:', error);
    }
  };

  return (
    <div className="w-64 bg-white border-r border-gray-200 px-3 py-4 flex flex-col h-full">
      {/* User Info */}
      <div className="px-4 py-3 mb-6 bg-gray-50 rounded-lg">
        <p className="text-sm font-medium text-gray-900">{profile?.name}</p>
        <p className="text-xs text-gray-500">{profile?.email}</p>
        <span className="mt-1 inline-flex items-center px-2 py-1 text-xs font-medium rounded-full bg-blue-100 text-blue-800">
          {isAdmin() ? 'Administrador' : 'Asesor'}
        </span>
      </div>

      <nav className="flex-1">
        <ul className="space-y-1">
          {navItems.map((item) => (
            <li key={item.to}>
              <NavLink
                to={item.to}
                onClick={onClose}
                className={({ isActive }) =>
                  `flex items-center px-4 py-2 text-sm rounded-lg ${
                    isActive
                      ? 'bg-blue-50 text-blue-700'
                      : 'text-gray-700 hover:bg-gray-50'
                  }`
                }
              >
                <item.icon className="w-5 h-5 mr-3" />
                {item.label}
              </NavLink>
            </li>
          ))}
        </ul>
      </nav>

      <div className="mt-auto">
        <button
          onClick={handleLogout}
          className="flex items-center px-4 py-2 text-sm text-gray-700 hover:bg-gray-50 rounded-lg w-full"
        >
          <LogOut className="w-5 h-5 mr-3" />
          Cerrar Sesión
        </button>
      </div>
    </div>
  );
}