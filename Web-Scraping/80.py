# -*- coding: utf-8 -*-
"""
Created on Wed Jun 14 10:04:31 2023

@author: Evann Lim
"""

# -*- coding: utf-8 -*-
"""
Spyder Editor

This is a temporary script file.
"""
#dependencies

import time
import json
import os
from selenium import webdriver
from selenium.webdriver.common.by import By
from selenium.webdriver.common.keys import Keys
from selenium.webdriver.chrome.options import Options
from selenium.webdriver.support.ui import Select


#verification_code_elements = soup.select ()


# Set up Chrome driver with custom download directory
chrome_options = Options()

# Disable the resource hungry elements that are not directly useful like the ff:
chrome_options.add_argument("--disable-gpu")    
chrome_options.add_argument("--kiosk-printing")  # Open print dialog automatically

settings = {"recentDestinations": [{"id": "Save as PDF", "origin": "local", "account": ""}], "selectedDestinationId": "Save as PDF", "version": 2}
prefs = {'printing.print_preview_sticky_settings.appState': json.dumps(settings), 'savefile.default_directory':r"C:\Users\Evann Lim\Downloads\HYT\WEB SCRAPING PDF"}

chrome_options.add_experimental_option('prefs', prefs)

driver = webdriver.Chrome(options=chrome_options)

# Access the OIG URL
driver.get("https://www.mbp.state.md.us/bpqapp/")
 
#<script src="https://www.google.com/recaptcha/api.js" async def></script>

# Prompt the user to enter the last name and/or first name
#<div classs = "g-recaptcha" data-sitekey="YOUR_PUBLIC_KEY" ></div>

last_name = input("Please enter LAST NAME: ")
#first_name = input("and/or FIRST NAME: ")


# Find the last name input element and send the user input
last_name_input = driver.find_element(By.ID, "LastName")
last_name_input.send_keys(last_name)

# Find the first name input element and send the user input
#first_name_input = driver.find_element(By.ID, "ctl00_cpExclusions_txtSPFirstName")
#first_name_input.send_keys(first_name)


# Locate and click the search button
search_button = driver.find_element(By.ID, "btnLastName")
search_button.click()

# Wait for the search results to load
time.sleep(2)

listofelements = driver.find_elements(By.XPATH,'//*[@name="listbox_Names"]/option') #to take all elements matching xpath
for i in range(len(listofelements)):
    print(listofelements[i].text) #print all elements of list

time.sleep(4)

license_number = input("\n PLEASE TYPE THE LICENSE NUMBER FROM THE LIST:")

cancel_button = driver.find_element(By.ID, "btnCancelNames")
cancel_button.click()

license_number_input = driver.find_element(By.ID, "Lic_No")
license_number_input.send_keys(license_number)
license_search = driver.find_element(By.ID, "btnLICNO")
license_search.click()
getprofile = driver.find_element(By.ID, "btnLICNO2")
getprofile.click()

time.sleep(1)

driver.execute_script('window.print();')

# Simulate pressing Ctrl+P to open the print dialog
driver.find_element(By.TAG_NAME, 'body').send_keys(Keys.CONTROL + 'p')




# Click the "Print" button
#print_button = driver.find_element(By.ID, "ctl00_cpExclusions_Button1")
#print_button.click()




# Wait for the download to complete (you may need to adjust the wait time based on the file size and network speed)
time.sleep(3)

#__________________________________________

# Simulate pressing Ctrl+P to open the print dialog
driver.find_element(By.TAG_NAME, 'body').send_keys(Keys.CONTROL + 'p')

# Specify the directory path
directory = r"C:\Users\Evann Lim\Downloads\HYT\WEB SCRAPING PDF"

# List all files in the directory
files = os.listdir(directory)

# Print the list of files
for file in files:
    print(file)

# Specify the file name to be renamed
old_file_name = "Maryland Board of Physicians Practitioner Profile.pdf"

# Specify the new file name
new_file_name = f"{last_name}_{license_number}.pdf"

# Rename the file
old_file_path = os.path.join(directory, old_file_name)
new_file_path = os.path.join(directory, new_file_name)
os.rename(old_file_path, new_file_path)

# Close the WebDriver
driver.quit()