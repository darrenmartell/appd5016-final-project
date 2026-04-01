import { useState, useEffect } from 'react';
import { FontAwesomeIcon } from '@fortawesome/react-fontawesome';
import { faUser, faCaretDown } from '@fortawesome/free-solid-svg-icons';
import { useAuthContext } from '../../context/AuthContext'
import { Link } from 'react-router-dom'

const Navbar = ({ searchTerm, setSearchTerm }) => {
  const { setToken, setUser, user, isAuthenticated } = useAuthContext();
  const [isDropdownOpen, setIsDropdownOpen] = useState(false);
  const toggleDropdown = () => setIsDropdownOpen(!isDropdownOpen);

  useEffect(() => {
    // Set a timeout to hide the div
    if (isDropdownOpen) {
      const timerId = setTimeout(() => {
        setIsDropdownOpen(false);
      }, 5000); // 5 seconds timeout

      // Cleanup function to clear the timeout
      return () => {
        clearTimeout(timerId);
      };
    }
  }, [isDropdownOpen]);

  return (
    <header className="w-full bg-[#141414] border-b border-[#333] p-4 sticky z-1">
      <nav className="flex justify-between items-center">
        {/* Logo and system name */}
        <div className="text-2xl font-bold text-white flex gap-2 items-center">
          <div className="w-10 h-10 bg-[#e50914] rounded-full" />
          Harlen Coben Netflix Series
        </div>
        {
          !isAuthenticated ?
            // Login Button
            <div className="flex items-center space-x-6">
              <>
                <div className="flex items-center space-x-6">
                  <Link to={'/login'} className="text-[#b3b3b3] hover:text-white transition-colors">Login</Link>
                </div>
                <div className="flex items-center space-x-6">
                  <Link to={'/register'} className="text-[#b3b3b3] hover:text-white transition-colors">Register</Link>
                </div>
              </>

            </div>
            :
            // Search bar and icons
            <div className="flex items-center space-x-6 text-[#b3b3b3]">
              <input
                type="text"
                placeholder="Search"
                className="hidden md:block px-3 py-1 bg-[#333] border border-[#444] text-white rounded-md focus:outline-none focus:ring focus:border-[#e50914] transition-all duration-300 placeholder:text-[#888]"
                value={searchTerm}
                onChange={(e) => setSearchTerm(e.target.value)}
              />

              {/* Dropdown for profile */}
              <div className="relative">
                <button
                  className="flex items-center space-x-2 text-[#b3b3b3] hover:text-white transition-colors"
                  onClick={toggleDropdown}
                >
                  <FontAwesomeIcon icon={faUser} />
                  <span className="hidden md:block font-medium">
                    {user?.email}
                  </span>
                  <FontAwesomeIcon icon={faCaretDown} />
                </button>

                {isDropdownOpen && (
                  <div className="absolute right-0 mt-4 w-48 bg-[#222] border border-[#333] shadow-lg rounded-md z-10">
                    <ul className="py-2">
                      {/* <li className="px-4 py-2 text-[#b3b3b3] hover:bg-[#333] hover:text-white cursor-pointer transition-colors">
                        <Link onClick={toggleDropdown} to={'/changepassword'}>Change Password</Link>
                      </li> */}

                      <li className="px-4 py-2 text-[#b3b3b3] hover:bg-[#333] hover:text-white cursor-pointer transition-colors" onClick={() => {
                        setToken(null);
                        setUser(null);
                      }}>
                        Logout
                      </li>
                    </ul>
                  </div>
                )}
              </div>
            </div>
        }
      </nav>
    </header >
  );
};

export default Navbar;
