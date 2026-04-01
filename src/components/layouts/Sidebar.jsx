import SidebarItem from './SidebarItem';
import { FontAwesomeIcon } from '@fortawesome/react-fontawesome';
import {
  faChartPie,
  faUsers,
  faArrowLeft,
  faArrowRight,
} from '@fortawesome/free-solid-svg-icons';



const Sidebar = ({ isCollapsed, toggleSidebar }) => {
  const sidebarItems = [
    { href: '/admin/home', label: 'Dashboard', icon: faChartPie },
    { href: '/admin/users', label: 'User Management', icon: faUsers },
    { href: '/admin/series', label: 'Series', icon: faUsers },
  ];

  return (
    <aside
      className={`${
        isCollapsed ? 'w-14' : 'w-64'
      } h-full bg-[#1a1a1a] border-r border-[#333] transition-all duration-300 ease-in-out relative`}
    >
      <button
        onClick={toggleSidebar}
        className="absolute -right-2.5 top-0 w-6 h-6 flex justify-center items-center hover:bg-[#444] rounded-full transition cursor-pointer focus:outline-none bg-[#333] text-[#b3b3b3]"
      >
        {isCollapsed ? (
          <FontAwesomeIcon icon={faArrowRight} />
        ) : (
          <FontAwesomeIcon icon={faArrowLeft} />
        )}
      </button>

      {/* Sidebar Navigation */}
      <nav className="mt-4">
        <ul>
          {sidebarItems.map((item) => (
            <SidebarItem
              key={item.href}
              href={item.href}
              label={item.label}
              isCollapsed={isCollapsed}
              icon={item.icon}
            />
          ))}
        </ul>
      </nav>
    </aside>
  );
};

export default Sidebar;
