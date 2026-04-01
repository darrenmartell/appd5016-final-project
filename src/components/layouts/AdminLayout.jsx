import { useState } from 'react';
import { Outlet } from 'react-router-dom';
import Navbar from './Navbar';
import Sidebar from './Sidebar';
import { useQuery } from '@tanstack/react-query'
import config from '../../config';

const AdminLayout = () => {
  const [isSidebarCollapsed, setIsSidebarCollapsed] = useState(false);
  const [searchTerm, setSearchTerm] = useState('');

  const toggleSidebar = () => {
    setIsSidebarCollapsed(!isSidebarCollapsed);
  };

  const fetchSeries = async () => {
    const response = await fetch(`${config.API_URL}/series`)
    const data = await response.json()
    return data
  }

  const {
    data: series = [],
    isLoading,
    error
  } = useQuery({
    queryKey: ["seriesCache"],
    queryFn: fetchSeries
  })

  return (
    <div className="h-screen flex flex-col bg-[#141414]">
      {/* Full-width Header */}
      <Navbar searchTerm={searchTerm} setSearchTerm={setSearchTerm} />

      {/* Sidebar and Content Below */}
      <div className="flex flex-grow overflow-hidden bg-[#141414]">
        {/* Sidebar */}
        <Sidebar
          isCollapsed={isSidebarCollapsed}
          toggleSidebar={toggleSidebar}
        />

        {/* Main Content */}
        <div className="flex-grow p-4 overflow-y-auto bg-[#141414]">
          <Outlet context={{ series, isLoading, error, searchTerm }} />
        </div>
      </div>
    </div>
  );
};

export default AdminLayout;
